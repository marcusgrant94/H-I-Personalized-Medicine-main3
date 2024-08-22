//
//  H_I_Personalized_MedicineApp.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 5/14/22.
//

import SwiftUI
import FirebaseCore
import UserNotifications
import CloudKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn
import UIKit
import FacebookCore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        
        // Register for remote notifications
        registerForPushNotifications(application)
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        
        // Check and handle the user's sign-in state
        handleUserSignInState()
        
        // Facebook and Google sign-in handling
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url) ||
               ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    func handleUserSignInState() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                // User is signed in, re-register for push notifications
                self?.registerForPushNotifications(UIApplication.shared)
                // Optionally, re-fetch the FCM token and update in Firestore
                Messaging.messaging().token { token, error in
                    if let error = error {
                        print("Error fetching FCM token: \(error.localizedDescription)")
                    } else if let token = token {
                        self?.updateFCMTokenInFirestore(token: token)
                    }
                }
            }
        }
    }

    
    func updateFCMToken() {
            guard let token = Messaging.messaging().fcmToken else { return }
            // Update token in Firestore or where you store user data
            print("Update token: \(token)")
        }

    func registerForPushNotifications(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    // Handle remote notification registration.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Application registered for remote notifications.")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("Firebase registration token: \(fcmToken)")
        updateFCMTokenInFirestore(token: fcmToken)
    }

    func updateFCMTokenInFirestore(token: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(userID)
        userRef.updateData(["fcmToken": token]) { error in
            if let error = error {
                print("Error updating token: \(error.localizedDescription)")
            } else {
                print("FCM token updated in Firestore successfully.")
            }
        }
    }

    
    
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle display notification in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
  
    // Handle user interaction with the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Check if it is a CloudKit notification
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject]),
           let queryNotification = notification as? CKQueryNotification,
           let recordID = queryNotification.recordID {
                let container = CKContainer(identifier: "iCloud.random.H-I-Personalized-Medicine")
                container.publicCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
                    if let record = record {
                        // Here, you can examine the record to see what kind of update has occurred
                    } else if let error = error {
                        print("Error fetching record: \(error.localizedDescription)")
                    }
                }
        }

        completionHandler()
    }
}



@main
struct H_I_Personalized_MedicineApp: App {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var usersViewModel = UsersViewModel()
    @StateObject var exerciseLogViewModel = ExerciseLogViewModel()
    @StateObject var appointmentViewModel = AppointmentViewModel(userRole: "user")
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    
    
    var body: some Scene {
        WindowGroup {
            ContentView(usersViewModel: UsersViewModel()).environmentObject(authViewModel).environmentObject(usersViewModel).environmentObject(appointmentViewModel)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                                    UIApplication.shared.applicationIconBadgeNumber = 0
                                }
//            NewAccountView().environmentObject(AuthViewModel())
//            LogInView().environmentObject(authViewModel)
//            ChatView(recipientID: "SampleRecipientID").environmentObject(UsersViewModel())
//            ExerciseView(logViewModel: exerciseLogViewModel)
//            AddExerciseDetailedView()
//            ScheduleAppointmentView(appointmentViewModel: AppointmentViewModel(), usersViewModel: usersViewModel)
            
        }
    }
}
