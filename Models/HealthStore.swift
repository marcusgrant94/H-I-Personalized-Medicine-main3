//
//  HealthStore.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 5/26/24.
//

import Foundation
import HealthKit

class HealthStore {
    var healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToShare: Set = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .leanBodyMass)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        ]

        healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: { success, error in
            completion(success)
        })
    }
    
    func fetchData(for type: HKQuantityTypeIdentifier, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
            completion(0.0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let options: HKStatisticsOptions
        let unit: HKUnit
        switch type {
        case .stepCount:
            options = .cumulativeSum
            unit = HKUnit.count()
        case .activeEnergyBurned:
            options = .cumulativeSum
            unit = HKUnit.kilocalorie()
        case .distanceWalkingRunning:
            options = .cumulativeSum
            unit = HKUnit.meter()
        case .flightsClimbed:
            options = .cumulativeSum
            unit = HKUnit.count()
        case .heartRate, .bodyMass, .bodyMassIndex, .bodyFatPercentage, .leanBodyMass, .respiratoryRate, .restingHeartRate:
            options = .discreteAverage
            unit = HKUnit.unit(for: type)
        default:
            options = .cumulativeSum
            unit = HKUnit.count()
        }
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options) { _, result, _ in
            guard let result = result else {
                completion(0.0)
                return
            }
            
            let value: Double
            switch options {
            case .cumulativeSum:
                value = result.sumQuantity()?.doubleValue(for: unit) ?? 0.0
            case .discreteAverage:
                value = result.averageQuantity()?.doubleValue(for: unit) ?? 0.0
            default:
                value = 0.0
            }
            
            completion(value)
        }
        
        healthStore?.execute(query)
    }
    
    func fetchAllData(completion: @escaping ([String: Double]) -> Void) {
        let types: [HKQuantityTypeIdentifier] = [
            .stepCount, .heartRate, .bodyMass, .activeEnergyBurned,
            .distanceWalkingRunning, .flightsClimbed, .bodyMassIndex,
            .bodyFatPercentage, .leanBodyMass, .respiratoryRate, .restingHeartRate
        ]
        
        var results = [String: Double]()
        let group = DispatchGroup()
        
        for type in types {
            group.enter()
            fetchData(for: type) { value in
                results[type.rawValue] = value
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
}

private extension HKUnit {
    static func unit(for identifier: HKQuantityTypeIdentifier) -> HKUnit {
        switch identifier {
        case .heartRate:
            return HKUnit.count().unitDivided(by: HKUnit.minute())
        case .bodyMass, .leanBodyMass:
            return HKUnit.gramUnit(with: .kilo)
        case .bodyMassIndex, .bodyFatPercentage:
            return HKUnit.percent()
        case .respiratoryRate, .restingHeartRate:
            return HKUnit.count().unitDivided(by: HKUnit.minute())
        default:
            return HKUnit.count()
        }
    }
}





