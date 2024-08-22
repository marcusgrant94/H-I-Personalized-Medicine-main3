//
//  AppointmentViewModel.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/7/23.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct Appointment: Identifiable {
    let id: String
    let patientID: String
    let nurseID: String
    let date: Date
    let status: String // such as "Scheduled", "Completed", "Cancelled", etc.
    let type: String
    let patientName: String
    let duration: String
    var cancellationReason: String?
    var phoneNumber: String?
}


class AppointmentViewModel: ObservableObject {
    var userRole: String
    @Published var appointments = [Appointment]()
    private var db = Firestore.firestore()

    init(userRole: String) {
            self.userRole = userRole
            fetchAppointments(userRole: userRole) // Pass the user role here
        }

    func fetchAppointments(userRole: String) {
        let collectionRef = db.collection("appointments")

        let query: Query
        if userRole == "admin" { // If user is admin (nurse), fetch all appointments
            query = collectionRef
        } else if let userID = Auth.auth().currentUser?.uid { // If user is not admin, fetch appointments for the logged-in user
            query = collectionRef.whereField("patientID", isEqualTo: userID)
        } else {
            print("No user ID found")
            return
        }

        query.addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            self.appointments = documents.map { queryDocumentSnapshot -> Appointment in
                    let data = queryDocumentSnapshot.data()
                let id = queryDocumentSnapshot.documentID

                let timestamp = data["date"] as? Timestamp
                let date = timestamp?.dateValue() ?? Date()
                let phoneNumber = data["phoneNumber"] as? String

                // Check if the date has passed and the status is "Scheduled", then update to "Completed"
                var status = data["status"] as? String ?? ""
                if date < Date() && status == "Scheduled" {
                    status = "Completed"
                    self.updateAppointmentStatusInDatabase(appointmentID: id, newStatus: status) // Update the status in the database
                }

                let patientID = data["patientID"] as? String ?? ""
                let nurseID = data["nurseID"] as? String ?? ""
                let type = data["type"] as? String ?? ""
                let patientName = data["patientName"] as? String ?? ""
                let duration = data["duration"] as? String ?? ""
                let cancellationReason = data["cancellationReason"] as? String

                return Appointment(id: id, patientID: patientID, nurseID: nurseID, date: date, status: status, type: type, patientName: patientName, duration: duration, cancellationReason: cancellationReason, phoneNumber: phoneNumber)
            }
        }
    }
    
    
    
    private func updateAppointmentStatusInDatabase(appointmentID: String, newStatus: String) {
        db.collection("appointments").document(appointmentID).updateData([
            "status": newStatus
        ]) { error in
            if let error = error {
                print("Error occurred while updating status: \(error.localizedDescription)")
            } else {
                print("Appointment status updated successfully.")
            }
        }
    }





    func scheduleAppointment(patientID: String, nurseID: String, date: Date, type: String, duration: String, phoneNumber: String? = nil, completion: @escaping (Error?) -> Void) {
        // Fetch the user's name from the Firestore
        db.collection("users").document(patientID).getDocument { document, error in
            if let error = error {
                print("Error fetching user: \(error)")
                completion(error)
                return
            }

            guard let document = document, document.exists, let userData = document.data(), let patientName = userData["name"] as? String else {
                print("User not found or name missing")
                completion(NSError(domain: "com.yourapp", code: 1, userInfo: nil)) // Replace with a suitable error
                return
            }

            // Construct the appointment data
            var appointmentData: [String: Any] = [
                "nurseID": nurseID,
                "patientID": patientID,
                "date": date,
                "status": "Pending Confirmation",
                "type": type,
                "patientName": patientName,
                "duration": duration
                // other properties
            ]
            
            if let phoneNumber = phoneNumber {
                   appointmentData["phoneNumber"] = phoneNumber
               }

            // Save appointmentData to Firestore (adjust to your specific logic)
            self.db.collection("appointments").addDocument(data: appointmentData) { error in
                    completion(error)
                }
            }
    }


    func updateAppointmentStatus(appointment: Appointment, newStatus: String, cancellationReason: String, completion: @escaping (Error?) -> Void) {
        db.collection("appointments").document(appointment.id).updateData([
            "status": newStatus,
            "cancellationReason": cancellationReason // <-- Include the cancellation reason
        ]) { error in
            if let error = error {
                print("Error occurred: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Appointment status updated successfully.")
                completion(nil)
            }
        }
    }


    func deleteAppointment(_ appointment: Appointment) {
        db.collection("appointments").document(appointment.id).delete { err in
            if let err = err {
                print("Error removing appointment: \(err)")
            } else {
                print("Appointment successfully removed!")
            }
        }
    }
    
    func durationInMinutes(duration: String) -> Int {
        if duration == "30 minutes" {
            return 30
        } else if duration == "45 minutes" {
            return 45
        } else if duration == "60 minutes" {
            return 60
        } else {
            return 0 // default or error case
        }
    }

    
    func calculateBlockedTimeslots() -> [Date] {
        var blockedTimes = [Date]()
        for appointment in appointments {
            let startDate = appointment.date
            let durationMinutes = durationInMinutes(duration: appointment.duration)
            let endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate)!
            var currentTime = startDate
            while currentTime < endDate {
                blockedTimes.append(currentTime)
                currentTime = Calendar.current.date(byAdding: .minute, value: 30, to: currentTime)! // assuming 30-min granularity
            }
        }
        return blockedTimes
    }
    
    func cancelAppointment(appointment: Appointment, cancellationReason: String, completion: @escaping (Error?) -> Void) {
        db.collection("appointments").document(appointment.id).updateData([
            "status": "Cancelled",
            "cancellationReason": cancellationReason // <-- Include the cancellation reason
        ]) { error in
            if let error = error {
                print("Error occurred: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Appointment cancelled successfully.")
                completion(nil)
            }
        }
    }
    
    func confirmAppointment(appointment: Appointment, completion: @escaping (Error?) -> Void) {
        db.collection("appointments").document(appointment.id).updateData([
            "status": "Scheduled"
        ]) { error in
            if let error = error {
                print("Error occurred: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Appointment confirmed successfully.")
                completion(nil)
            }
        }
    }

    func declineAppointment(appointment: Appointment, declineReason: String, completion: @escaping (Error?) -> Void) {
        db.collection("appointments").document(appointment.id).updateData([
            "status": "Cancelled",
            "cancellationReason": declineReason
        ]) { error in
            if let error = error {
                print("Error occurred: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Appointment declined successfully.")
                completion(nil)
            }
        }
    }




}

