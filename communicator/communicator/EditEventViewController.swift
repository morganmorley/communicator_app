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
    
    @IBOutlet weak var locationApprovedButton: UIButton!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var editTimesButton: UIButton!
    @IBOutlet weak var rsvpButton: UIButton!
    
    var rsvpEnabled = false
    var isApproved = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        // Load details from remote source or create a new reference
        if let event = eventID {
            ref?.child("events").child("drafts").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.hasChild(event){
                    self.ref?.child("events").child("drafts").child(event).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? Dictionary<String,Dictionary<String,String>> {
                            self.populate(with: value)
                            self.eventRef = self.ref?.child("events").child("drafts").child(event)
                        }
                    })
                } else {
                    self.ref?.child("events").child("current").child(event).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? Dictionary<String,Dictionary<String,String>> {
                            self.populate(with: value)
                            self.eventRef = self.ref?.child("events").child("current").child(event)
                        }
                    })
                }
            })
        } else {
            eventRef = ref?.child("events").child("drafts").childByAutoId()
            eventID = eventRef!.key as String
            groupID = ""
            startTimeLabel.text = DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
            endTimeLabel.text = DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
        }

    }
    
    func populate(with value: [String: [String: String]]) {
        self.titleTextField.text = value["details"]?["title"] ?? ""
        self.descriptionTextView.text = value["details"]?["desc"] ?? ""
        if self.groupID == nil {
            self.groupID = value["details"]?["group"] ?? ""
        }
        if value["details"]?["rsvp"]! == "true" {
            rsvpButton.setTitle("Remove RSVP Option", for: .normal)
        }
        let datetime = DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
        startTimeLabel.text = datetime
        endTimeLabel.text = datetime
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func stringToDate(_ dateTime: String) -> Date {
        //Splits dateTime strings into discreet units for comparison
        var dateFromFirebase = DateComponents()
        let months = ["January": 1, "February": 2, "March": 3, "April": 4, "May": 5, "June": 6, "July": 7, "August": 8, "September": 9, "October": 10, "November": 11, "December": 12]
        let splitInput = dateTime.components(separatedBy: " at ")
        let date = splitInput[0].components(separatedBy: ", ")
        let monthAndDay = date[1].components(separatedBy: " ")
        let wholeTime = splitInput[1].components(separatedBy: " ")
        var hourAndMinute = wholeTime[0].components(separatedBy: ":")
        
        //Fill the dateFromFirebase
        dateFromFirebase.month = months[monthAndDay[0]]
        dateFromFirebase.day = Int(monthAndDay[1])
        dateFromFirebase.year = Int(date[2])
        if wholeTime[1] == "PM" {
            dateFromFirebase.hour = Int(hourAndMinute[0])! + 12 + 1 //for end time
        } else {
            dateFromFirebase.hour = Int(hourAndMinute[0])! + 1 //for end time
        }
        dateFromFirebase.minute = Int(hourAndMinute[1])
        
        //Turn back into date and return
        let dateFromComponents = Calendar.current.date(from: dateFromFirebase)!
        return dateFromComponents
    }
    
    func gatherDetails() -> Dictionary<String,String> {
        var eventDetails = Dictionary<String,String>()
        eventDetails["title"] = titleTextField.text ?? ""
        eventDetails["desc"] = descriptionTextView.text ?? ""
        eventDetails["start_datetime"] = startTimeLabel.text ??  DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
        eventDetails["end_datetime"] = endTimeLabel.text ??  DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
        eventDetails["rsvp"] = String(rsvpEnabled)
        eventDetails["groupID"] = groupID ?? ""
        eventDetails["location"] = locationTextField.text ?? ""
        return eventDetails
    }

    func saveEvent(isDraft: Bool) {
        var status = ""
        if isDraft {
            status = "drafts"
        } else {
            status = "current"
        }
        
        let eventDetails = gatherDetails()
        if eventDetails["title"] == "" { return }

        //Post the data to firebase
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            if isDraft {
                self.ref?.child("events").child(status).child(self.eventID!).setValue(["details": eventDetails])
                self.ref?.child("events").child(status).child(self.eventID!).child("linked_users").child(userID).setValue("admin")
            } else {
                if (self.stringToDate(eventDetails["start_datetime"]!) < self.stringToDate(eventDetails["end_datetime"]!)) {
                    if (Date() < self.stringToDate(eventDetails["end_datetime"]!)) {
                        self.ref?.child("events").child(status).child(self.eventID!).setValue(["details": eventDetails])
                        self.ref?.child("events").child(status).child(self.eventID!).child("linked_users").child(userID).setValue("admin")
                    }
                }
            }
            self.ref?.child("user_details").child(userID).child("linked_events").child(self.eventID!).setValue(eventDetails["title"])
            if self.groupID != "" {
                self.ref?.child("groups").child("drafts").child(self.groupID!).child("linked_events").child(self.eventID!).setValue(eventDetails["title"])
            }
            if !isDraft {
                //save group in promoted posts as it's published.
                let calendar = Calendar.current
                let year = String(calendar.component(.year, from: self.stringToDate(eventDetails["start_datetime"]!)))
                let postDetails = [year: [self.eventID!: ["name": self.titleTextField.text as? String ?? "", "role": "admin"]]]
                self.ref?.child("user_profiles").child(userID).child("current").child(year).observeSingleEvent(of: .value, with: { (snapshot) in
                    if !snapshot.hasChild(self.eventID!) {
                        self.ref?.child("user_profiles").child(userID).child("possible").setValue(postDetails)
                    } else {
                        self.ref?.child("user_profiles").child(userID).child("current").setValue(postDetails)
                        self.ref?.child("user_profiles").child(userID).child("possible").setValue(postDetails)
                    }
                            
                })
                //delete draft content as its being published
                self.ref?.child("events").child("drafts").child(self.eventID!).removeValue { (error, ref) in
                    if error != nil {
                        print("error \(String(describing: error))")
                    }
                }
                //Dismiss the popover
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    
    @IBAction func savePost(_ sender: Any) {
        if isApproved {
            saveEvent(isDraft: false)
        }
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        //delete any saved content in events/drafts
        self.ref?.child("events").child("drafts").child(self.eventID!).removeValue { (error, ref) in
            if error != nil {
                print("error \(String(describing: error))")
            }
        }
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func rsvpButtonTapped(_ sender: Any) {
        rsvpEnabled = !rsvpEnabled
        if rsvpEnabled {
            rsvpButton.setTitle("Remove RSVP", for: .normal)
        } else {
            rsvpButton.setTitle("Enable RSVP", for: .normal)
        }
    }

    @IBAction func editTimesButtonTapped(_ sender: Any) {
        saveEvent(isDraft: true)
        self.performSegue(withIdentifier: "goToTimeSet", sender: self)
    }

    @IBAction func deleteEvent(_ sender: Any) {
        //delete event from all user accounts
        ref?.child("user_details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let allUsers = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                for (key, value) in allUsers {
                    if (value["linked_events"]?[self.eventID!]) != nil {
                        self.ref?.child("user_details").child(key).child("linked_events").child(self.eventID!).removeValue { (error, ref) in
                            if error != nil {
                                print("error \(String(describing: error))")
                            }
                        }
                    }
                }
                //delete from events/drafts
                self.ref?.child("events").child("drafts").child(self.eventID!).removeValue { (error, ref) in
                    if error != nil {
                        print("error \(String(describing: error))")
                    }
                }
                //delete from events/current
                self.ref?.child("events").child("current").child(self.eventID!).removeValue { (error, ref) in
                    if error != nil {
                        print("error \(String(describing: error))")
                    }
                }
            }
            //Dismiss the popover
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        })

    }
    @IBAction func locationApproved(_ sender: Any) {
        isApproved = true
        locationApprovedButton.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTimeSet" {
            if let setTimeViewController = segue.destination as? SetTimeViewController {
                //send appropriate eventID for saving the time on Set Tiime View Controller
                setTimeViewController.eventIDForLookup = eventID!
                setTimeViewController.pastViewController = self
            }
        }
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
        locationTextField.resignFirstResponder()
    }
    
}
