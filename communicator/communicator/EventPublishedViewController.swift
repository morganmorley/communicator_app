//
//  EventPublishedViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/20/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class EventPublishedViewController: UIViewController {

    var ref: FIRDatabaseReference?
    var eventRef: FIRDatabaseReference?
    var userRef: FIRDatabaseReference?
    var eventID: String?
    var userID: String?
    var adminID: String?

    var isAdmin: Bool = false
    var shelf: Bool = false
    var rsvp: Bool = false

    @IBOutlet weak var adminButton: UIButton!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var locationTextView: UITextView!
    @IBOutlet weak var endDateTextView: UITextView!
    @IBOutlet weak var endDayTextView: UITextView!
    @IBOutlet weak var endMonthYearTextView: UITextView!
    @IBOutlet weak var startToEndTimeTextView: UITextView!
    @IBOutlet weak var shelfEditButton: UIBarButtonItem!
    @IBOutlet weak var startMonthYearTextView: UITextView!
    @IBOutlet weak var startDateTextView: UITextView!
    @IBOutlet weak var startDayTextView: UITextView!
    @IBOutlet weak var rsvpButton: UIButton!
    
    func findAdminID() {
        // Find the UID of the admin to search for their username in users
        eventRef?.child("linked_users").observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventUsers = snapshot.value as? Dictionary<String,String> {
                for (user, role) in eventUsers {
                    if role == "admin" {
                        self.adminID = user
                    }
                }
                if self.adminID != nil {
                    //get admin's username for adminButton title
                    self.ref?.child("user_details").child(self.adminID!).child("details").child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                        if let username = snapshot.value as? String {
                            self.adminButton.setTitle(username, for: .normal)
                        } else {
                            print("Could not find admin's username.")
                        }
                    })
                    //set admin view
                    if (self.adminID == self.userID) {
                        self.isAdmin = true
                        self.shelfEditButton.title = "Edit" // eventually will turn into edit button and be false
                        self.rsvpButton.setTitle("RSVP List",for: .normal)
                        self.shelf = true
                    }
                } else {
                    print("Could not find admin linked to the event: " + String(describing: self.eventID!))
                }
            } else {
                print("Could not find users linked to the event: " + String(describing: self.eventID!))
            }
            self.setLabels()
        })
    }
    
    func divideDatetimes(start: String, end: String) {
        //Splits datetime strings into discreet units for publishing
        let startSplitInput = start.components(separatedBy: " at ")
        let startDate = startSplitInput[0].components(separatedBy: ", ")
        let startMonthAndDay = startDate[1].components(separatedBy: " ")
        let startWholeTime = startSplitInput[1]
        self.startMonthYearTextView.text = startMonthAndDay[0] + " " + startDate[2]
        self.startDayTextView.text = startDate[0]
        self.startDateTextView.text = startMonthAndDay[1]
        let endSplitInput = end.components(separatedBy: " at ")
        let endDate = endSplitInput[0].components(separatedBy: ", ")
        if endDate != startDate {
            let endMonthAndDay = endDate[1].components(separatedBy: " ")
            self.endMonthYearTextView.text = endMonthAndDay[0] + " " + endDate[2]
            self.endDayTextView.text = endDate[0]
            self.endDateTextView.text = endMonthAndDay[1]
        } else {
            self.endMonthYearTextView.isHidden = true
            self.endDayTextView.isHidden = true
            self.endDateTextView.isHidden = true
        }
        let endWholeTime = endSplitInput[1]
        self.startToEndTimeTextView.text = startWholeTime + " to " + endWholeTime
    }
    
    func setLabels() {
        //Set the date, time, title, and place labels as well as description scroll view
        eventRef?.child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventDetails = snapshot.value as? Dictionary<String,String> {
                self.divideDatetimes(start: eventDetails["start_datetime"]!, end: eventDetails["end_datetime"]!)
                self.titleTextView.text = eventDetails["title"]!
                self.locationTextView.text = eventDetails["location"]!
                self.descTextView.text = eventDetails["desc"]!
                if (eventDetails["rsvp"]! == "true") {
                    self.rsvpButton.isHidden = false
                }
                if !self.isAdmin {
                    self.rsvpButton.setTitle("RSVP", for: .normal)
                }
                // set rsvp label and button; set addDeleteButton title
                self.userRef?.child("linked_events").child(self.eventID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let value = snapshot.value as? String {
                        if ((value == "rsvp") || (value == "shelf")) {
                            self.shelfEditButton.title = "Unshelf"
                        }
                        if (value == "rsvp") {
                            self.rsvpButton.setTitle("Cancel RSVP", for: .normal)
                            self.shelf = true
                        }
                    }
                })
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up references to the database and find the current user's ID
        ref = FIRDatabase.database().reference()
        eventRef = ref?.child("events").child("current").child(eventID!)
        userID = FIRAuth.auth()?.currentUser?.uid
        userRef = ref?.child("user_details").child(userID!)
        
        //Default settings for view
        rsvpButton.isHidden = true
        shelfEditButton.title = "Shelf"

        //Query the database and set the labels
        findAdminID()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func changeShelfSettings(button: Int) {
        if ((!shelf) && (!rsvp)) {
            //delete event from user's linked events and event's linked users
            userRef?.child("linked_events").child(eventID!).removeValue()
            eventRef?.child("linked_users").child(userID!).removeValue()
            shelfEditButton.title = "Shelf"
            rsvpButton.setTitle("RSVP", for: .normal)
        } else {
            switch (button) {
            case 1:
                // shelf button tapped
                if (shelf && (!rsvp)) {
                    // add event to user's shelf
                    userRef?.child("linked_events").child(eventID!).setValue(titleTextView.text)
                    eventRef?.child("linked_users").child(userID!).setValue("shelf")
                    shelfEditButton.title = "Unshelf"
                } else if ((!shelf) && rsvp) {
                    // remove event from shelf that user is rsvp-ed to
                    rsvp = false
                    changeShelfSettings(button: 0)
                }
                break
            case 2:
                //rsvp button tapped
                if ((!shelf) && rsvp) {
                    // rsvp to an event user doesn't have added to their shelf
                   shelf = true
                } else if (shelf && (!rsvp)) {
                    // remove rsvp from an event user does have added to their shelf
                    userRef?.child("linked_events").child(eventID!).setValue(titleTextView.text as String)
                    eventRef?.child("linked_users").child(userID!).removeValue()
                    rsvpButton.setTitle("RSVP", for: .normal)
                }
                break
            default:
                break
            }
            if (shelf && rsvp) {
                eventRef?.child("linked_users").child(userID!).setValue("rsvp")
                userRef?.child("linked_events").child(eventID!).setValue(titleTextView.text as String)
                shelfEditButton.title = "Unshelf"
                rsvpButton.setTitle("Cancel RSVP", for: .normal)
            }
        }
    }
    
    @IBAction func adminButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "goToProfile", sender: self)
    }
    
    @IBAction func shelfEditButtonTapped(_ sender: Any) {
        if !isAdmin {
            shelf = !shelf
            changeShelfSettings(button: 1)
        } else {
            self.performSegue(withIdentifier: "goToEditEvent", sender: self)
        }
    }

    @IBAction func rsvpButtonTapped(_ sender: Any) {
        if !isAdmin {
            rsvp = !rsvp
            changeShelfSettings(button: 2)
        } else {
            self.performSegue(withIdentifier: "goToRoster", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                // send appropriate UID to userForLookup variable on Profile View Controller
                profileViewController.userIDForLookup = adminID!
            }
        } else if segue.identifier == "goToRoster" {
            if let rosterViewController = segue.destination as? RosterViewController {
                // send along the appropriate post type (groups or events) and the postId
                rosterViewController.postID = eventID!
            }
        } else if segue.identifier == "goToEditEvent" {
            if let editEventViewController = segue.destination as? EditEventViewController {
                // send along the appropriate post type (groups or events) and the postId
                editEventViewController.eventID = eventID!
            }
        }
    }

}
