//
//  EditEventViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 4/2/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class EditEventViewController: UIViewController {
    
    var ref: FIRDatabaseReference?
    var eventRef: FIRDatabaseReference?
    var groupID: String?
    var eventID: String?
    var isDraft: Bool?
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descTextField: UITextField!
    @IBOutlet weak var placeTextField: UITextField!
    @IBOutlet weak var displayRSVP: UISwitch!
    @IBOutlet weak var roomResponsibility: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        if (isDraft == nil) { isDraft = true }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveActions() {
        //TODO - save posts as drafts before final save
        //Post the data to firebase
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            // gather event details
            var eventDetails = Dictionary<String,String>()
            eventDetails["title"] = titleTextField.text ?? ""
            eventDetails["desc"] = descTextField.text ?? ""
            eventDetails["place"] = placeTextField.text ?? ""
            eventDetails["rsvp"] = String(displayRSVP.isOn)
            let adminDict = [userID: "admin"]
            
            if !isDraft! {
                // room reservation responsibility is acknowledged, checks if inserted an empty title or place
                //TODO - try to get time from draft posts
                //let currentDate = Date()
                //if ((dateTimeSetter.date < currentDate) || (!roomResponsibility.isOn)) { return }
                if ((eventDetails["title"] == "") || (eventDetails["place"] == "")) { return }
            }
            
            // post information to the database
            if let event = eventID {
                if isDraft! {
                    eventRef = ref?.child("draft_posts").child("events").child(event)
                } else {
                    eventRef = ref?.child("posts").child("events").child(event)
                    //TODO - DELETE DRAFT POST if successful
                }
            } else {
                if isDraft! {
                    eventRef = ref?.child("draft_posts").child("events").childByAutoId()
                } else {
                    eventRef = ref?.child("posts").child("events").childByAutoId()
                }
                eventID = eventRef!.key as String
            }
            ref?.child("users").child(userID).child("linked_events").child(eventID!).setValue("admin")
            eventRef?.setValue(["details": eventDetails, "linked_users": adminDict])
            
            //link event to group
            let linkedEvent = [eventID!: "public"]
            if let group = groupID {
                ref?.child("posts").child("groups").child(group).child("linked_events").child(group).setValue(linkedEvent)
            }
        }
    }
    
    @IBAction func savePost(_ sender: Any) {
        isDraft = false
        saveActions()
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        //delete any saved content in draft_posts
        self.ref?.child("draft_posts").child("events").child(self.eventID!).removeValue { (error, ref) in
            if error != nil {
                print("error \(String(describing: error))")
            }
        }

        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTimeSet" {
            saveActions()
            if let setTimeViewController = segue.destination as? SetTimeViewController {
                //send appropriate eventID for saving the time on Set Tiime View Controller
                setTimeViewController.eventID = eventID!
                setTimeViewController.isDraft = isDraft!
            }
        }
    }
    
}
