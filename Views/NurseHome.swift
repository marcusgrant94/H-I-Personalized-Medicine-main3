//
//  NurseHome.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/8/23.
//

import SwiftUI
import FirebaseAuth

struct NurseHome: View {
    @EnvironmentObject var usersViewModel: UsersViewModel
    @ObservedObject var appointmentViewModel: AppointmentViewModel
    let currentUser = Auth.auth().currentUser
    @State private var profileImage: Image? = nil
    
    var scheduledAppointmentsCount: Int {
        let count = appointmentViewModel.appointments.filter { $0.status == "Scheduled" }.count
        print("Appointments:", appointmentViewModel.appointments)
        print("Scheduled appointments count:", count)
        return count
    }
    
    var todaysAppointments: [Appointment] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        return appointmentViewModel.appointments.filter { appointment in
            appointment.status == "Scheduled" &&
            appointment.date >= startOfDay &&
            appointment.date < endOfDay
        }
    }
    
    var tomorrowsAppointments: [Appointment] {
        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        let endOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfTomorrow)!
        return appointmentViewModel.appointments.filter { appointment in
            appointment.status == "Scheduled" &&
            appointment.date >= startOfTomorrow &&
            appointment.date < endOfTomorrow
        }
    }
    
    var pastAppointments: [Appointment] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return appointmentViewModel.appointments.filter { appointment in
            appointment.date < startOfDay
        }
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
           NavigationView {
               VStack {
                   HStack {
                       if let profileImage = profileImage {
                           profileImage
                               .resizable()
                               .frame(width: 50, height: 50)
                               .clipShape(Circle())
                               .offset(y: -25)
                       }
                       
                       VStack(alignment: .leading) {
                           Text(greetingTime())
                               .font(.title2)
                           
                           Text("You have \(scheduledAppointmentsCount) \(scheduledAppointmentsCount == 1 ? "appointment" : " upcoming appointments")")
                               .foregroundColor(.gray)
                               .font(.subheadline)
                       }
                       
                       Spacer()
                   }
                   .padding()
                   Spacer()
                   Text("Today's Appointments")
                       .offset(x: -55)
                       .font(.title3)
                       .padding()
                   
                   if todaysAppointments.isEmpty {
                       Image("ghost")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 250, height: 250)
                       Text("Your Schedule is empty!")
                   } else {
                       List(todaysAppointments) { appointment in
                           AppointmentCardView(appointment: appointment, usersViewModel: usersViewModel)
                       }
                       .listStyle(PlainListStyle())
                   }
                   
                   Spacer()
               }
           }
           .onAppear {
               fetchProfileImageIfNeeded()
           }
       }

       func fetchProfileImageIfNeeded() {
           if let currentUserID = currentUser?.uid,
              let user = usersViewModel.users.first(where: { $0.id == currentUserID }),
              let profileImageUrl = user.profileImageURL {
               fetchProfileImage(url: profileImageUrl)
           } else {
               print("User not found or profile image URL missing")
           }
       }
    
    func fetchProfileImage(url: String) {
        guard let imageUrl = URL(string: url) else { return }
        
        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = Image(uiImage: uiImage)
                }
            }
        }.resume()
    }
    
    func greetingTime() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let currentTime = formatter.string(from: date)
        
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 6..<12 : greeting = "Good Morning"
        case 12..<17 : greeting = "Good Afternoon"
        case 17..<22 : greeting = "Good Evening"
        default: greeting = "Good Night"
        }
        
        return "\(greeting), \((getUser()?.name) ?? "")\n It's currently \(currentTime)"
    }
    
    func getUser() -> User? {
        return usersViewModel.users.first { $0.id == currentUser?.uid }
    }
}



struct NurseHome_Previews: PreviewProvider {
    static var previews: some View {
        NurseHome(appointmentViewModel: AppointmentViewModel(userRole: "admin"))
            .environmentObject(UsersViewModel())
    }
}
