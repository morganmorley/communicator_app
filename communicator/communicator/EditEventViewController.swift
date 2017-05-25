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
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var endTimeTextView: UITextView!
    @IBOutlet weak var startTimeTextView: UITextView!
    @IBOutlet weak var editTimesButton: UIButton!
    @IBOutlet weak var placeApprovedButton: UIButton!
    @IBOutlet weak var descTextView: UITextView!
    
    @IBOutlet weak var locationTextView: UITextView!
    @IBOutlet weak var rsvpButton: UIButton!
    
    var rsvpEnabled = false
    
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
                            self.eventRef = self.ref?.child("groups").child("drafts").child(event)
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
            //TODO - POPULATE SOME FIELDS (DATETIME, GROUPID)
        }

    }
    
    func populate(with value: [String: [String: String]]) {
        self.titleTextView.text = value["details"]?["title"] ?? ""
        self.descTextView.text = value["details"]?["desc"] ?? ""
        if self.groupID == nil {
            self.groupID = value["details"]?["group"] ?? ""
        }
        if Bool((value["details"]?["rsvp"])!)! {
            rsvpButton.setTitle("Remove RSVP Option", for: .normal)
        }
        let datetime = DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
        startTimeTextView.text = datetime
        endTimeTextView.text = datetime
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func saveEvent(isDraft: Bool) {
        var status = ""
        if isDraft {
            status = "draft"
        } else {
            status = "current"
        }
        //Post the data to firebase
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            if let event = eventID {
                // gather event details
                var eventDetails = Dictionary<String,String>()
                eventDetails["title"] = titleTextView.text ?? ""
                eventDetails["desc"] = titleTextView.text ?? ""
                eventDetails["start_datetime"] = startTimeTextView.text ??  DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
                eventDetails["end_datetime"] = endTimeTextView.text ??  DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
                eventDetails["rsvp"] = String(rsvpEnabled)
                eventDetails["groupID"] = groupID
                eventDetails["location"] = locationTextView.text ?? ""
                
                //TODO - CHECK FOR ACCURATE TIMES
                
                // post details to the database
                ref?.child("events").child(status).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.hasChild(event){
                        self.ref?.child("events").child(status).child(event).setValue(["details": eventDetails])
                        self.ref?.child("events").child(status).child(event).child("linked_users").child(userID).setValue("admin")
                        if !isDraft {
                            //save group in promoted posts as it's published.
                            let calendar = Calendar.current
                            let year = String(calendar.component(.year, from: Date()))
                            let postDetails = [year: [event: ["name": self.titleTextView.text, "role": "admin"]]]
                            self.ref?.child("user_profiles").child(userID).child("hidden").child(year).observeSingleEvent(of: .value, with: { (snapshot) in
                                if !snapshot.hasChild(event) {
                                    self.ref?.child("user_profiles").child(userID).child("current").child(year).observeSingleEvent(of: .value, with: { (snapshot) in
                                        if !snapshot.hasChild(event) {
                                            self.ref?.child("user_profiles").child(userID).child("possible").child(year).child(event).setValue(postDetails)
                                        } else {
                                            self.ref?.child("user_profiles").child(userID).child("current").child(year).child(event).setValue(postDetails)
                                        }
                                    })

                                }
                            })
                        }
                    }else{
                        let adminDict = [userID: "admin"]
                        self.ref?.child("groups").child(status).setValue(["details": eventDetails, "linked_users": adminDict])
                    }
                    self.ref?.child("user_details").child(userID).child("linked_events").child(event).setValue(eventDetails["title"])
                    if !isDraft {
                        //delete draft content as its being published
                        self.ref?.child("events").child("drafts").child(event).removeValue { (error, ref) in
                            if error != nil {
                                print("error \(String(describing: error))")
                            }
                        }
                        //Dismiss the popover
                        self.presentingViewController?.dismiss(animated: true, completion: nil)
                    }
                    if self.groupID != "" {
                        self.ref?.child("groups").child("drafts").child(self.groupID!).child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
                            if !snapshot.hasChild(event) {
                                self.ref?.child("groups").child("drafts").child(self.groupID!).child("linked_events").child(event).setValue(eventDetails["title"])
                            } else {
                                self.ref?.child("groups").child("current").child(self.groupID!).child("linked_events").child(event).setValue(eventDetails["title"])
                            }
                        })
                    }
                })
            }
        }
    }

    
    @IBAction func savePost(_ sender: Any) {
        saveEvent(isDraft: false)
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
        })

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTimeSet" {
            if let setTimeViewController = segue.destination as? SetTimeViewController {
                //send appropriate eventID for saving the time on Set Tiime View Controller
                setTimeViewController.eventIDForLookup = eventID!
            }
        }
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextView.resignFirstResponder()
        descTextView.resignFirstResponder()
        locationTextView.resignFirstResponder()
    }
    
}
