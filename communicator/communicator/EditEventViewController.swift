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
    var userID: String?
    
    var rsvpDisplayed = false
    var roomReserved = false
    
    var fromStream: Bool?
    var fromShelf: Bool?
    
    @IBOutlet weak var roomResponsibility: UIButton!
    @IBOutlet weak var groupName: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var editTimeButton: UIButton!
    @IBOutlet weak var displayRSVPButton: UIButton!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var locationTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        userID = FIRAuth.auth()?.currentUser?.uid
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
        }
        if fromStream == nil {
            fromStream = false
        }
        if fromShelf == nil {
            fromShelf = false
        }

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
    
    func populate(with value: [String: [String: String]]) {
        self.titleTextField.text = value["details"]?["title"] ?? ""
        self.descTextView.text = value["details"]?["desc"] ?? ""
        self.locationTextField.text = value["details"]?["desc"] ?? ""
        self.groupID = value["details"]?["group"] ?? ""
        self.ref?.child("groups").child("current").child(groupID!).child("details").child("title").observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? String {
                self.groupName.text = value
            }
        })
        if value["details"]?["rsvp"]! == "true" {
            displayRSVPButton.setTitle("Remove RSVP", for: .normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func saveEvent(isDraft: Bool, segueID: String) {
        var status = ""
        if isDraft {
            status = "drafts"
        } else {
            status = "current"
        }
        
        eventRef?.child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? Dictionary<String,String> {
                var eventDetails = Dictionary<String,String>()
                eventDetails["title"] = self.titleTextField.text ?? ""
                eventDetails["admin"] = self.userID!
                eventDetails["desc"] = self.descTextView.text ?? ""
                eventDetails["start_datetime"] = value["start_datetime"] ?? ""
                eventDetails["end_datetime"] = value["end_datetime"] ?? ""
                eventDetails["rsvp"] = String(self.rsvpDisplayed)
                eventDetails["groupID"] = self.groupID ?? ""
                self.ref?.child("groups").child("current").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let groups = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                        for (group, data) in groups {
                            if let groupTitle = data["details"]?["title"] {
                                if (self.groupName.text as? String ?? "") == groupTitle {
                                    eventDetails["groupID"] = group
                                }
                            }
                        }
                    }
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
                            if self.groupID != "" {
                                self.ref?.child("groups").child("current").child("linked_users").observeSingleEvent(of: .value, with: { (snapshot) in
                                    if let users = snapshot.value as? Dictionary<String,String> {
                                        for (user, _) in users {
                                            self.ref?.child("user_details").child(user).child("linked_events").child(self.eventID!).setValue(eventDetails["title"])
                                            if user != userID {
                                                self.ref?.child("events").child(status).child(self.eventID!).child("linked_users").child(user).setValue("shelf")
                                            }
                                        }
                                    }
                                })
                            }
                        }
                        //delete draft content as its being published
                        self.ref?.child("events").child("drafts").child(self.eventID!).removeValue { (error, ref) in
                            if error != nil {
                                print("error \(String(describing: error))")
                            }
                        }
                        self.performSegue(withIdentifier: segueID, sender: self)
                    } else {
                        self.performSegue(withIdentifier: segueID, sender: self)
                    }

                })

            }
        })
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
            self.performSegue(withIdentifier: "goToStream", sender: self)
        })

    }
    
    @IBAction func roomResponse(_ sender: Any) {
        roomReserved = true
        roomResponsibility.isHidden = true
    }
    
    @IBAction func changeRSVP(_ sender: Any) {
        rsvpDisplayed = !rsvpDisplayed
        if rsvpDisplayed {
            displayRSVPButton.setTitle("Remove RSVP", for: .normal)
        } else {
            displayRSVPButton.setTitle("Display RSVP", for: .normal)
        }
    }
    
    @IBAction func editTime(_ sender: Any) {
        saveEvent(isDraft: true, segueID: "goToTimeSet")
    }

    @IBAction func savePost(_ sender: Any) {
        var segueID = ""
        if roomReserved {
            if fromShelf! {
                segueID = "goToShelf"
            } else if fromStream! {
                segueID = "goToStream"
            } else {
                segueID = "goToPublishedEvent"
            }
            saveEvent(isDraft: false, segueID: segueID)
        }
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        var segueID = ""
        if roomReserved {
            if fromShelf! {
                segueID = "goToShelf"
            } else if fromStream! {
                segueID = "goToStream"
            } else {
                segueID = "goToPublishedEvent"
            }
            //delete any saved content in events/drafts
            self.ref?.child("events").child("drafts").child(self.eventID!).removeValue { (error, ref) in
                if error != nil {
                    print("error \(String(describing: error))")
                }
            }
        }
        self.performSegue(withIdentifier: segueID, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTimeSet" {
            if let setTimeViewController = segue.destination as? SetTimeViewController {
                //send appropriate eventID for saving the time on Set Tiime View Controller
                setTimeViewController.eventID = eventID!
            }
        } else if segue.identifier == "goToPublishedEvent" {
            if let eventPublishedViewController = segue.destination as? EventPublishedViewController {
                //send appropriate eventID for saving the time on Set Tiime View Controller
                eventPublishedViewController.eventID = eventID!
            }
        }
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        descTextView.resignFirstResponder()
        locationTextField.resignFirstResponder()
    }
    
}
