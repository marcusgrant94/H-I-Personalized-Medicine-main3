//
//  TabBar.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 5/14/22.
//

import SwiftUI
import FirebaseAuth

struct TabBar: View {
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var appointmentViewModel: AppointmentViewModel

    var body: some View {
        TabView {
            if usersViewModel.currentUserRole == "user" {
                Home()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
            }
            
            if usersViewModel.currentUserRole == "admin" {
                NurseHome(appointmentViewModel: AppointmentViewModel(userRole: "admin"))
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
            }
            
            if usersViewModel.currentUserRole == "admin" {
                PatientsView()
                    .tabItem {
                        Label("Patients", systemImage: "person.2.fill")
                    }
            }
            
            if usersViewModel.currentUserRole == "user" {
                PatientMessageView()
                    .tabItem {
                        Label("Messages", systemImage: "message")
                    }
            }

            
            if usersViewModel.currentUserRole == "user", let uid = Auth.auth().currentUser?.uid {
                PatientTrackingView(userID: uid)
                    .tabItem {
                        Label("Tracking", systemImage: "list.clipboard")
                    }
            }
            
//            ServicesView()
//                .tabItem {
//                    Label("Services", systemImage: "cross.case.fill")
//                }
//
//            VisitStoreView()
//                .tabItem {
//                    Label("Store", systemImage: "cart")
//                }
            if usersViewModel.currentUserRole == "user" {
                ScheduleAppointmentView(appointmentViewModel: AppointmentViewModel(userRole: "user"), usersViewModel: usersViewModel)
                    .tabItem {
                        Label("Appointment", systemImage: "calendar.badge.plus")
                    }
            }
            
            if usersViewModel.currentUserRole == "admin" {
                ManageAppointmentsView().environmentObject(appointmentViewModel)
                    .tabItem {
                        Label("Appointment",systemImage: "calendar.badge.plus")
                    }
            }
            
            if usersViewModel.currentUserRole == "user" {
                ContactUsView()
                .tabItem {
                Label("Contact Us", systemImage: "envelope.fill")
            }
        }
            
            if usersViewModel.currentUserRole == "user" {
                FaqView()
                    .tabItem {
                        Label("FAQs", systemImage: "questionmark")
                    }
            }
            
            Group {
                
                if usersViewModel.currentUserRole == "user" {
                    AboutUsView()
                        .tabItem {
                            Label("About Us", systemImage: "person")
                        }
                }
                
//                if usersViewModel.currentUserRole == "user", let currentUser = usersViewModel.users.first(where: { $0.id == Auth.auth().currentUser?.uid }) {
//                    SettingsView2(user: currentUser)
//                        .tabItem {
//                            Label("Settings", systemImage: "gearshape")
//                        }
//                }
                
                if usersViewModel.currentUserRole == "user" {
                    HealthKitView()
                        .tabItem {
                            Label("HealthKit", systemImage: "person2")
                        }
                }
            }
            
        }
        .accentColor(Color(hue: 0.454, saturation: 0.991, brightness: 0.52, opacity: 0.911))
    }
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar().environmentObject(UsersViewModel())
    }
}
