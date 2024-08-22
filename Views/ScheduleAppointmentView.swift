//
//  ScheduleAppointmentView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/7/23.
//

import SwiftUI
import FirebaseAuth
import EventKit

struct ScheduleAppointmentView: View {
    @ObservedObject var appointmentViewModel: AppointmentViewModel
    @ObservedObject var usersViewModel: UsersViewModel
    @State private var currentDate = Date()
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var selectedType = "Meeting" // Default type
    @State private var selectedDuration = "30 minutes" // Default duration
    @State private var showingConfirmationAlert = false
    @State private var showingConflictAlert = false
    @State private var showingPhoneNumberAlert = false
    @State private var phoneNumber: String = ""
    @State private var showingTutorialAlert = false
    @State private var activeAlert: ActiveAlert?
    @State private var showingSuccessAlert = false
    let eventStore = EKEventStore()
    
    enum ActiveAlert: Identifiable {
            case phoneNumber, confirmation, conflict, success
            
            var id: Int {
                switch self {
                case .phoneNumber:
                    return 1
                case .confirmation:
                    return 2
                case .conflict:
                    return 3
                case .success:
                    return 4
                }
            }
        }


    // List of appointment types to choose from
    private let appointmentTypes = ["Meeting", "Wellness Evaluation Call", "Semaglutide Saturdays", "Wellness Strategy Call"]
    // List of appointment durations to choose from
    private let appointmentDurationMinutes = 30
    
    // List of available time slots
        private var availableTimeSlots: [Date] {
            var slots: [Date] = []
            let calendar = Calendar.current
            var time = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!

            let endTime = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: Date())!
            while time <= endTime {
                slots.append(time)
                time = calendar.date(byAdding: .minute, value: 30, to: time)!
            }

            return slots
        }
    
    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        return calendar.date(byAdding: timeComponents, to: calendar.date(from: dateComponents)!)!
    }

    
    var upcomingAppointments: [Appointment] {
        return appointmentViewModel.appointments.filter { $0.date >= currentDate && $0.status != "Cancelled" }
    }

    var pastAppointments: [Appointment] {
        return appointmentViewModel.appointments.filter { $0.date < currentDate || $0.status == "Cancelled" }
    }

    var body: some View {
        NavigationView {
            Form {
                DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)

                               // Picker for the time
                               Picker("Select time", selection: $selectedTime) {
                                   ForEach(availableTimeSlots, id: \.self) { time in
                                       Text("\(time, formatter: Self.timeFormatter)").tag(time)
                                   }
                               }
                
                Picker("Appointment Type", selection: $selectedType) {
                        ForEach(appointmentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }

                if selectedType == "Wellness Strategy Call" || selectedType == "Wellness Evaluation Call" {
                    TextField("Enter your phone number", text: Binding(
                        get: { phoneNumber },
                        set: { newValue in
                            phoneNumber = formattedPhoneNumber(from: newValue)
                        }
                    ))
                    .keyboardType(.phonePad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }


                Button("Request Appointment") {
                    if (selectedType == "Wellness Strategy Call" || selectedType == "Wellness Evaluation Call") && phoneNumber.isEmpty {
                        activeAlert = .phoneNumber
                    } else {
                        activeAlert = .confirmation
                    }
                }
                .alert(isPresented: $showingPhoneNumberAlert) {
                    Alert(
                        title: Text("Missing Information"),
                        message: Text("Please enter a phone number."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .alert(isPresented: $showingConfirmationAlert) {
                    Alert(
                        title: Text("Confirmation"),
                        message: Text("Are you sure you want to request this appointment?"),
                        primaryButton: .default(Text("Yes")) {
                            // Logic for scheduling the appointment
                            if !isTimeSlotAvailable(date: combinedDateTime) { // Use combinedDateTime instead of selectedDate
                                showingConflictAlert = true // Show alert if there's a conflict
                            } else {
                                guard let nurseID = usersViewModel.nurseID,
                                      let patientID = Auth.auth().currentUser?.uid else { return }

                                if selectedType != "Wellness Strategy Call" && selectedType != "Wellness Evaluation Call" {
                                    phoneNumber = ""
                                }

                                appointmentViewModel.scheduleAppointment(patientID: patientID, nurseID: nurseID, date: combinedDateTime, type: selectedType, duration: selectedDuration, phoneNumber: phoneNumber) { error in
                                    if error == nil {
                                        // Modify status to "Pending Confirmation"
                                        let newAppointment = Appointment(id: UUID().uuidString, patientID: patientID, nurseID: nurseID, date: combinedDateTime, status: "Pending Confirmation", type: selectedType, patientName: "Patient Name Here", duration: selectedDuration)
                                        let durationMinutes = appointmentViewModel.durationInMinutes(duration: selectedDuration)
                                        addAppointmentToCalendar(appointment: newAppointment, durationInMinutes: durationMinutes)
                                        appointmentViewModel.fetchAppointments(userRole: "user")
                                        phoneNumber = ""
                                        activeAlert = .success
                                    }
                                    
                                    // Handle other results
                                }
                            }
                        },
                        secondaryButton: .cancel(Text("No"))
                    )
                }

                // Section to show scheduled appointments
                Section(header: Text("Upcoming Appointments")) {
                                if upcomingAppointments.isEmpty {
                                    Text("No upcoming appointments.")
                                        .padding(.vertical, 5)
                                } else {
                                    ForEach(upcomingAppointments) { appointment in
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Date:").bold() + Text(" \(appointment.date, formatter: Self.dateFormatter)")
                                            Text("Type:").bold() + Text(" \(appointment.type)")
                                            Text("Duration:").bold() + Text(" \(appointment.duration)")
                                            Text("Status: ").bold() +
                                                Text(appointment.status.isEmpty ? "Scheduled" : appointment.status)
                                                .foregroundColor(getStatusColor(status: appointment.status))
                                            // Displaying the cancellation reason if the status is "Cancelled"
                                            if appointment.status == "Cancelled" {
                                                Text("Cancellation Reason:").bold() + Text(" \(appointment.cancellationReason ?? "N/A")")
                                            }
                                        }
                                        .padding(.vertical, 5)
                                    }
                                }
                            }

                            // Section to show past appointments
                            Section(header: Text("Past Appointments")) {
                                if pastAppointments.isEmpty {
                                    Text("No past appointments.")
                                        .padding(.vertical, 5)
                                } else {
                                    ForEach(pastAppointments) { appointment in
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Date:").bold() + Text(" \(appointment.date, formatter: Self.dateFormatter)")
                                            Text("Type:").bold() + Text(" \(appointment.type)")
                                            Text("Duration:").bold() + Text(" \(appointment.duration)")
                                            Text("Status: ").bold() +
                                                Text(appointment.status.isEmpty ? "Scheduled" : appointment.status)
                                                .foregroundColor(appointment.status == "Scheduled" ? .yellow : appointment.status == "Cancelled" ? .red : appointment.status == "Completed" ? .green : .primary)
                                            // Displaying the cancellation reason if the status is "Cancelled"
                                            if appointment.status == "Cancelled" {
                                                Text("Cancellation Reason:").bold() + Text(" \(appointment.cancellationReason ?? "N/A")")
                                            }
                                        }
                                        .padding(.vertical, 5)
                                    }
                                }
                            }
                        }
            .alert(item: $activeAlert) { alertType in
                            switch alertType {
                            case .phoneNumber:
                                return Alert(title: Text("Missing Information"),
                                             message: Text("Please enter a phone number."),
                                             dismissButton: .default(Text("OK")))
                            case .confirmation:
                                return Alert(
                                    title: Text("Confirmation"),
                                    message: Text("Are you sure you want to request this appointment?"),
                                    primaryButton: .default(Text("Yes")) {
                                        // Logic for scheduling the appointment
                                        if !isTimeSlotAvailable(date: combinedDateTime) {
                                            activeAlert = .conflict
                                        } else {
                                            guard let nurseID = usersViewModel.nurseID,
                                                  let patientID = Auth.auth().currentUser?.uid else { return }
                                            if selectedType != "Wellness Strategy Call" && selectedType != "Wellness Evaluation Call" {
                                                phoneNumber = ""
                                            }
                                            appointmentViewModel.scheduleAppointment(patientID: patientID, nurseID: nurseID, date: combinedDateTime, type: selectedType, duration: selectedDuration, phoneNumber: phoneNumber) { error in
                                                if error == nil {
                                                    // Modify status to "Pending Confirmation"
                                                    let newAppointment = Appointment(id: UUID().uuidString, patientID: patientID, nurseID: nurseID, date: combinedDateTime, status: "Pending Confirmation", type: selectedType, patientName: "Patient Name Here", duration: selectedDuration)
                                                    let durationMinutes = appointmentViewModel.durationInMinutes(duration: selectedDuration)
                                                    addAppointmentToCalendar(appointment: newAppointment, durationInMinutes: durationMinutes)
                                                    appointmentViewModel.fetchAppointments(userRole: "user")
                                                    phoneNumber = ""
                                                    activeAlert = .success
                                                }
                                                // Handle other results
                                            }
                                        }
                                    },
                                    secondaryButton: .cancel(Text("No"))
                                )
                            case .conflict:
                                return Alert(title: Text("Conflict"),
                                             message: Text("The selected time slot is not available. Please choose a different time."),
                                             dismissButton: .default(Text("OK")))
                            case .success:
                                return Alert(title: Text("Success"),
                                             message: Text("Appointment scheduled successfully. Please wait for confirmation."),
                                             dismissButton: .default(Text("OK")))
                            }
                        }
                    }
                }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func isTimeSlotAvailable(date: Date) -> Bool {
        let selectedEndTime = Calendar.current.date(byAdding: .minute, value: appointmentDurationMinutes, to: date)!
        
        for appointment in appointmentViewModel.appointments {
            let appointmentEndTime = Calendar.current.date(byAdding: .minute, value: appointmentDurationMinutes, to: appointment.date)!
            
            // Check for any overlap with existing appointments
            if (date >= appointment.date && date < appointmentEndTime) ||
               (selectedEndTime > appointment.date && selectedEndTime <= appointmentEndTime) ||
               (date <= appointment.date && selectedEndTime >= appointmentEndTime) {
                return false // Conflict found
            }
        }
        
        return true // No conflict
    }

}


func getStatusColor(status: String) -> Color {
       switch status {
           case "Scheduled":
               return .green
           case "Pending Confirmation":
               return .yellow
           case "Cancelled":
               return .red
           case "Completed":
               return .blue
           default:
               return .primary
       }
   }



func addAppointmentToCalendar(appointment: Appointment, durationInMinutes: Int) {
    let eventStore = EKEventStore()
    
    eventStore.requestAccess(to: .event) { (granted, error) in
        if granted {
            let event = EKEvent(eventStore: eventStore)
            event.title = "Appointment: \(appointment.type)"
            event.startDate = appointment.date
            event.endDate = Calendar.current.date(byAdding: .minute, value: durationInMinutes, to: appointment.date)!
            event.notes = "Duration: \(appointment.duration)"
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch let e as NSError {
                print("Error saving event: \(e)")
            }
        } else {
            // Handle error
        }
    }
}

func formattedPhoneNumber(from value: String) -> String {
    var digits = value.filter { "0"..."9" ~= $0 }
    var formatted = ""

    if digits.count > 0 {
        formatted += "("
    }

    for i in 0..<digits.count {
        if i == 3 {
            formatted += ")-"
        } else if i == 6 {
            formatted += "-"
        }

        let index = digits.index(digits.startIndex, offsetBy: i)
        formatted.append(digits[index])
    }

    return formatted
}




struct ScheduleAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleAppointmentView(appointmentViewModel: AppointmentViewModel(userRole: "user"), usersViewModel: UsersViewModel())
            .environmentObject(UsersViewModel())
    }
}
