//
//  EventComposeViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/20/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class EventComposeViewController: UIViewController {

    var ref: FIRDatabaseReference?
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateTimeSetter: UIDatePicker!
    let dateTimeFormatter = DateFormatter()
    var dateTimeDisplay: String = ""
    @IBOutlet weak var placeTextField: UITextField!
    @IBOutlet weak var roomResponsibility: UISwitch!
    @IBOutlet weak var displayRSVP: UISwitch!
    @IBOutlet weak var descTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func savePost(_ sender: Any) {
        //Post the data to firebase
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            // gather event details
            var eventDetails = Dictionary<String,String>()
            eventDetails["title"] = titleTextField.text ?? ""
            eventDetails["desc"] = descTextField.text ?? ""
            eventDetails["place"] = placeTextField.text ?? ""
            eventDetails["rsvp"] = String(displayRSVP.isOn)
            eventDetails["date_time"] = dateTimeDisplay
            let adminDict = [userID: "admin"]

            // checks the date has not passed and room reservation responsibility is acknowledged
            let currentDate = Date()
            if (dateTimeSetter.date < currentDate) || (!roomResponsibility.isOn) { return }
            // checks if inserted an empty title
            if eventDetails["title"] == "" || eventDetails["place"] == "" { return }
            
            // post information to the database
            let eventRef = ref?.child("posts").child("events").childByAutoId()
            let eventID = eventRef!.key as String
            ref?.child("users").child(userID).child("linked_events").child(eventID).setValue("admin")
            eventRef?.setValue(["details": eventDetails, "linked_users": adminDict])
            
            //Dismiss the popover
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func dateTimeSetterChanged(_ sender: Any) {
        //set date and time for storage
        dateTimeFormatter.dateStyle = DateFormatter.Style.full
        dateTimeDisplay = dateTimeFormatter.string(from: dateTimeSetter.date) + " at ?"
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
