//
//  FirstViewController.swift
//  BJJAppV5
//
//  Created by Ryan Schulte on 9/30/19.
//  Copyright © 2019 meyita. All rights reserved.
//
//2019-10-01: The program keeps erroring out due to the username being nill.  I think it is because I added it in
//  after it was already loaded on a phone.

import UIKit
import AWSCore
import AWSAuthUI
import AWSDynamoDB
import AWSMobileClient
import AWSUserPoolsSignIn
import AWSCognitoIdentityProvider

class FirstViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var ClassCount:Int = 0
    var cntClassBjjGi:Int = 0
    var cntClassNoGi:Int = 0
    var cntClassJudo:Int = 0
    var cntClassWrestling:Int = 0
    var cntClassOpenMat:Int = 0
    var cntClassDrill:Int = 0
    var cntClassSeminar:Int = 0
    var classItem = Set<String>()
    var deviceid:String = (UIDevice.current.identifierForVendor?.uuidString)!
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var beltrank:String = ""
    let objectMapper = AWSDynamoDBObjectMapper.default()
    let queryExpression = AWSDynamoDBQueryExpression()
    let scanExpression = AWSDynamoDBScanExpression()
    let username:String = AWSMobileClient.default().self.username ?? "nil"
    var classes: [String]!
    
    
    @IBOutlet weak var picker_date: UIDatePicker!
    @IBOutlet weak var picker_class: UIPickerView!
    @IBOutlet weak var img_belt: UIImageView!
    @IBOutlet weak var label_BjjGiClasses: UILabel!
    @IBOutlet weak var label_BjjNoGiClasses: UILabel!
    @IBOutlet weak var label_JudoClasses: UILabel!
    @IBOutlet weak var label_Seminars: UILabel!
    @IBOutlet weak var label_WrestlingClasses: UILabel!
    @IBOutlet weak var label_OpenMats: UILabel!
    @IBOutlet weak var label_DrillClasses: UILabel!
    
    @IBOutlet weak var selector_classLogRange: UISegmentedControl!
    @IBAction func selector_ClassRange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            print("Selector Index is o")
        case 1:
            print("Selector Index is 1")
            GetBeltImage()
        case 2:
            print("Selector Index is 2")
        case 3:
            print("Selector Index is 3")
        case 4:
            DisplayClassTotals()
            print("Selector Index is 4")
        default:
            print("Default")
        }
    }
    
    @IBAction func btn_SubmitClassLog(_ sender: Any) {
        postToClassLogin()
        cntClassDrill = 0
        cntClassBjjGi = 0
        cntClassSeminar = 0
        cntClassJudo = 0
        cntClassNoGi = 0
        cntClassWrestling = 0
        cntClassOpenMat = 0
        AllClassesLogScan()
    }
    
    @IBAction func btn_logout(_ sender: Any) {
        AWSMobileClient.default().signOut()
        self.showSignIn()
    }
    
    @IBAction func btn_UserAttributes(_ sender: Any) {
        print("Button Pressed")
        Last7DayClassTotals()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSignIn()
        initializeAWSMobileClient()
        picker_class.delegate = self
        picker_class.dataSource = self
        classes = ["Select Class", "BJJ Gi", "BJJ NoGi", "Judo", "OpenMat", "Wrestling", "Drill", "Seminar"]
    }
    
    func initializeAWSMobileClient() {
        AWSMobileClient.default().initialize { (userState, error) in
            //self.addUserStateListener() // Register for user state changes
            if let userState = userState {
                switch(userState){
                case .signedIn: // is Signed IN
                    let userAttributes = self.response
                    self.checkForLogin()
                case .signedOut: // is Signed OUT
                    print("Logged Out")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                case .signedOutUserPoolsTokenInvalid: // User Pools refresh token INVALID
                    print("User Pools refresh token is invalid or expired.")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                case .signedOutFederatedTokensInvalid: // Facebook or Google refresh token INVALID
                    print("Federated refresh token is invalid or expired.")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                default:
                    self.showSignIn()
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func showSignIn() {
        AWSMobileClient.default()
            .showSignIn(navigationController: self.navigationController!,
                             signInUIOptions: SignInUIOptions(
                                   canCancel: false,
                                   logoImage: UIImage(named: "TXBjj"),
                                    backgroundColor: UIColor.white)) { (result, err) in
                                     DispatchQueue.main.async {
                                        print("User successfully logged in")
                                    }
        }
    }
    
    func checkForLogin() {
        if !AWSSignInManager.sharedInstance().isLoggedIn{
            AWSAuthUIViewController.presentViewController(with: self.navigationController!, configuration: nil) { (provider, error)  in
            if error == nil {
                print("success")
            } else { print(error?.localizedDescription ?? "no value") }
            }
        }
    }
    
    func UserAttributes() {
        AWSMobileClient.default().addUserStateListener(self) { (userState, info) in
            switch (userState) {
            case .guest:
                print("user is in guest mode.")
                self.showSignIn()
            case .signedOut:
                print("user signed out")
                self.showSignIn()
            case .signedIn:
                print("user is signed in.")
            case .signedOutUserPoolsTokenInvalid:
                print("need to login again.")
                self.showSignIn()
            case .signedOutFederatedTokensInvalid:
                print("user logged in via federation, but currently needs new tokens")
                self.showSignIn()
            default:
                print("unsupported")
                self.showSignIn()
            }
        }
    }
    
    func postToClassLogin() {
        let selectedDate = picker_date.date
        let format = DateFormatter()
        format.dateStyle = DateFormatter.Style.medium
        let username:String = AWSMobileClient.default().self.username!
        let deviceid:String = (UIDevice.current.identifierForVendor?.uuidString)!
        let newClassLoginDate:String = (format.string(from: selectedDate))
        print(newClassLoginDate)
        let newClass = classes[picker_class.selectedRow(inComponent: 0)]
        print("Class title: \(newClass)")
        let newUsername = username
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
        let itemToCreate:TblClassLog = TblClassLog()
        
        itemToCreate._userId = deviceid
        itemToCreate._date = newClassLoginDate
        itemToCreate._class = newClass
        itemToCreate._username = newUsername
        itemToCreate._uldate = newClassLoginDate
        
        objectMapper.save(itemToCreate, completionHandler: {(error:Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                self.FailureSubAlert()
                return
            }
            print("Class successfully Logged")
        })
    }
    
    func classAmountsQuery() {
        let val:String = username
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#username = :username"
        queryExpression.expressionAttributeNames = [
            "#username": "username",
        ]
        queryExpression.expressionAttributeValues = [
            ":username": val,
        ]
        objectMapper.query(TblClassLog.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Scan Error: \(error)")
                return
            }
            DispatchQueue.main.async {
                if (response != nil) {
                    print("Got a response.")
                    for item in (response?.items)!{
                        print("Output Data: \(item)")
                }
                return
            } else {
                print("No data found")
                return
                }
            }
        })
    }
    
    func AllClassesLogScan() {
        print("From AllClassesLogScan Username: \(username)")
        let val:String = username
        scanExpression.filterExpression = "username = :val"
        scanExpression.expressionAttributeValues = [":val": val]
        objectMapper.scan(TblClassLog.self, expression: scanExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Scan Error: \(error)")
                return
            }
            DispatchQueue.main.async {
                if (response != nil) {
                    print("Got a response.")
                    for item in (response?.items)!{
                        self.ClassCount = self.ClassCount + 1
                        self.ClassCount = (response?.items.count)!
                        if let ClassId = item.value(forKey: "_class") as? NSString {
                            switch ClassId {
                            case "BJJ GI":
                                self.cntClassBjjGi = self.cntClassBjjGi + 1
                                self.label_BjjGiClasses.text = String(self.cntClassBjjGi)
                            case "BJJ NoGi":
                                self.cntClassNoGi = self.cntClassNoGi + 1
                                self.label_BjjNoGiClasses.text = String(self.cntClassNoGi)
                            case "Judo":
                                self.cntClassJudo = self.cntClassJudo + 1
                                self.label_JudoClasses.text = String(self.cntClassJudo)
                            case "Wrestling":
                                self.cntClassWrestling = self.cntClassWrestling + 1
                                self.label_WrestlingClasses.text = String(self.cntClassWrestling)
                            case "Open Mat":
                                self.cntClassOpenMat = self.cntClassOpenMat + 1
                                self.label_OpenMats.text = String(self.cntClassOpenMat)
                            case "Drill":
                                self.cntClassDrill = self.cntClassDrill + 1
                                self.label_DrillClasses.text = String(self.cntClassDrill)
                            //Seminar
                            case "Seminar":
                                self.cntClassSeminar = self.cntClassSeminar + 1
                                self.label_Seminars.text = String(self.cntClassSeminar)
                            default:
                                print("Class not recognized.")
                            }
                        }
                    }
                    return
            } else {
                print("No data found")
                return
                }
            }
        })
    }
    
    func DisplayClassTotals() {
        cntClassDrill = 0
        cntClassBjjGi = 0
        cntClassSeminar = 0
        cntClassJudo = 0
        cntClassNoGi = 0
        cntClassWrestling = 0
        cntClassOpenMat = 0
        AllClassesLogScan()
    }
    
    func Last7DayClassTotals() {
        let last7Days = Date.getDates(forLastNDays: 7)
        let dateMark = last7Days[6]
        //let val:String = username
        scanExpression.filterExpression = "uldate > :dateMark"
        scanExpression.expressionAttributeValues = [":dateMark": dateMark]
        objectMapper.scan(tbl_Users.self, expression: scanExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Scan Error: \(error)")
                return
            }
            DispatchQueue.main.async {
                if (response != nil){
                    print("Got a date response.")
                    for item in (response?.items)! {
                        print("Itmes from 7 day class")
                        print(item)
                    }
                } else {
                    print("No Data for bely rank available.")
                }
            }
        })
    }
    
    func GetUserAttributes() {
        print("Start GetUserAttributes")
        queryExpression.keyConditionExpression = "#username = :username"
        queryExpression.expressionAttributeNames = ["#username": "username",]
        queryExpression.expressionAttributeValues = [":username": username]
        objectMapper.query(tbl_Users.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Scan Error: \(error)")
                return
            }
            DispatchQueue.main.async {
                if (response != nil) {
                    print("Got a response.")
                    print("Response: \(String(describing: response))")
                    for item in (response?.items)!{
                        print("Output Data: \(item)")
                }
                return
            } else {
                print("No data found")
                return
                }
            }
        })    }
    
    func GetBeltImage() {
        print("From GetBeltImage: Username: \(username)")
        let val:String = username
        scanExpression.filterExpression = "username = :val"
        scanExpression.expressionAttributeValues = [":val": val]
        objectMapper.scan(tbl_Users.self, expression: scanExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Scan Error: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                if (response != nil){
                    print("Got a beltrank response.")
                    for item in (response?.items)! {
                        print("belt rank value seperation")
                        if let beltrank = item.value(forKey: "_beltrank") as? String {
                            print("assigned belt rank of: \(beltrank)")
                            switch beltrank {
                            case "White":
                                self.img_belt.image = UIImage(named: "WhiteBelt")
                            case "Blue":
                                self.img_belt.image = UIImage(named: "BlueBelt")
                            case "Purple":
                                self.img_belt.image = UIImage(named: "PurpleBelt")
                            case "Brown":
                                self.img_belt.image = UIImage(named: "BrownBelt")
                            case "Black":
                                self.img_belt.image = UIImage(named: "BlackBelt")
                            default:
                                self.img_belt.image = UIImage(named: "WhiteBelt")
                            }
                        }
                        
                    }
                } else {
                    print("No Data for bely rank available.")
                }
            }
        })
    }
    
    func SuccessfulSubAlert(){
        let alert = UIAlertController(title: "Successfully Submitted", message: "Your attendance has been submitted.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func FailureSubAlert(){
        let alert = UIAlertController(title: "Failure Submitting", message: "There was an error submitting your class. Please try again later.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return classes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return classes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let theClasses = classes[row]
    }

}

extension Date {
    static func getDates(forLastNDays nDays: Int) -> [String] {
        let cal = NSCalendar.current
        // start with today
        var date = cal.startOfDay(for: Date())

        var arrDates = [String]()

        for _ in 1 ... nDays {
            // move back in time by one day:
            date = cal.date(byAdding: Calendar.Component.day, value: -1, to: date)!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let dateString = dateFormatter.string(from: date)
            arrDates.append(dateString)
        }
        return arrDates
    }
}

