//
//  CancellationSheet.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/9/23.
//

import SwiftUI

struct CancellationSheet: View {
    @Binding var appointment: Appointment?
    @Binding var cancellationReason: String
    @ObservedObject var appointmentViewModel: AppointmentViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Please provide a reason for cancellation:")
            TextField("Reason", text: $cancellationReason)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Cancel Appointment") {
                if let appointment = appointment {
                    appointmentViewModel.updateAppointmentStatus(appointment: appointment, newStatus: "Cancelled", cancellationReason: cancellationReason) { error in
                        // Handle the result
                        if error == nil {
                            // Dismiss the sheet if there was no error
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .buttonStyle(DefaultButtonStyle())
        }
        .padding()
    }
}

//struct CancellationSheet_Previews: PreviewProvider {
//    static var previews: some View {
//        CancellationSheet()
//    }
//}
