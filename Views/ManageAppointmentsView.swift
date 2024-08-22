//
//  ManageAppointmentsView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/7/23.
//

import SwiftUI

struct ManageAppointmentsView: View {
    @ObservedObject var appointmentViewModel = AppointmentViewModel(userRole: "admin")
    @State private var showingCancellationSheet = false
    @State private var showingActionSheet = false
    @State private var cancellationReason = ""
    @State private var selectedAppointment: Appointment? = nil

    var upcomingAppointments: [Appointment] {
        return appointmentViewModel.appointments.filter { $0.date >= Date() && $0.status != "Cancelled" }
    }

    var pastAppointments: [Appointment] {
        return appointmentViewModel.appointments.filter { $0.date < Date() || $0.status == "Cancelled" }
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Upcoming Appointments")) {
                    ForEach(upcomingAppointments) { appointment in
                        AppointmentRow(appointment: appointment)
                            .onTapGesture {
                                selectedAppointment = appointment
                                showingActionSheet = true
                            }
                            .actionSheet(isPresented: $showingActionSheet) {
                                ActionSheet(title: Text("Manage Appointment"), buttons: [
                                    .default(Text("Confirm")) {
                                        if let appointment = selectedAppointment {
                                            // Add a method in the ViewModel to confirm the appointment
                                            appointmentViewModel.confirmAppointment(appointment: appointment) { error in
                                                if error != nil {
                                                    // Handle the error, maybe show an alert
                                                } else {
                                                    print("Appointment confirmed.")
                                                }
                                            }
                                        }
                                    },
                                    .destructive(Text("Decline")) {
                                        showingCancellationSheet = true
                                    },
                                    .cancel()
                                ])
                            }
                    }
                    .onDelete(perform: deleteAppointments)
                }

                Section(header: Text("Past Appointments")) {
                    ForEach(pastAppointments) { appointment in
                        AppointmentRow(appointment: appointment)
                    }
                    .onDelete(perform: deleteAppointments)
                }
            }
            .listStyle(InsetGroupedListStyle()) // For a grouped appearance
            .navigationTitle("Manage Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCancellationSheet) {
                CancellationSheet(appointment: $selectedAppointment, cancellationReason: $cancellationReason, appointmentViewModel: appointmentViewModel)
            }
        }
    }

    private func AppointmentRow(appointment: Appointment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Patient:").bold() + Text(" \(appointment.patientName)")
                Text("Date:").bold() + Text(" \(appointment.date, formatter: Self.dateFormatter)")
                Text("Type:").bold() + Text(" \(appointment.type)")
                Text("Duration:").bold() + Text(" \(appointment.duration)")
                if let phoneNumber = appointment.phoneNumber, (appointment.type == "Wellness Strategy Call" || appointment.type == "Wellness Evaluation Call") {
                    Text("Phone Number:").bold() + Text(" \(phoneNumber)")
                }
            }
            .padding()
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Status: ")
                Text(appointment.status)
                    .foregroundColor(getStatusColor(status: appointment.status))
                Button(action: {
                    selectedAppointment = appointment
                    showingActionSheet = true
                }) {
                    Text("Manage")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                }

                .offset(x: 15, y: 30)
            }
            .padding(.horizontal)
        }
    }

    private func deleteAppointments(at offsets: IndexSet) {
        for index in offsets {
            let appointment = appointmentViewModel.appointments[index]
            appointmentViewModel.deleteAppointment(appointment)
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
    
    
}




struct ManageAppointmentsView_Previews: PreviewProvider {
    static var previews: some View {
        ManageAppointmentsView().environmentObject(AppointmentViewModel(userRole: "admin"))
    }
}

