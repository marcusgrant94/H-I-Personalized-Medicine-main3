//
//  AppointmentCardView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/8/23.
//

import SwiftUI
import FirebaseAuth

struct AppointmentCardView: View {
    let appointment: Appointment
    @ObservedObject var usersViewModel: UsersViewModel

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(alignment: .center) {
            // Profile picture (retrieve from usersViewModel)
            if let user = usersViewModel.users.first(where: { $0.id == appointment.patientID }),
               let profileImageURL = user.profileImageURL,
               let imageURL = URL(string: profileImageURL) {
                URLImage(url: imageURL)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading) {
                // Name of the patient
                Text(appointment.patientName)
                    .font(.headline)
                
                // Age of the patient
                if let user = usersViewModel.users.first(where: { $0.id == appointment.patientID }),
                   let age = user.age {
                    Text("Age: \(age)")
                        .font(.subheadline)
                }


                // Meeting type
                Text(appointment.type)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Date
                Text("\(appointment.date, formatter: AppointmentCardView.dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.leading)

            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
        .shadow(radius: 5)
    }
}




struct AppointmentCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock appointment
        let appointment = Appointment(
            id: "1",
            patientID: "patient1",
            nurseID: "nurse1",
            date: Date(),
            status: "Scheduled",
            type: "General Checkup",
            patientName: "John Doe",
            duration: "30 minutes"
        )

        // Create a mock UsersViewModel
        let usersViewModel = UsersViewModel()
        
        return AppointmentCardView(appointment: appointment, usersViewModel: usersViewModel)
    }
}




