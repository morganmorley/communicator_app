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

    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var adminButton: UIButton!
    @IBOutlet weak var addDeleteButton: UIButton!
    @IBOutlet weak var rosterButton: UIButton!
    @IBOutlet weak var rsvpSwitch: UISwitch!
    @IBOutlet weak var rsvpLabel: UILabel!
    
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
                    self.ref?.child("users").child(self.adminID!).child("details").child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? String {
                            self.adminButton.setTitle(value, for: .normal)
                        } else {
                            print("Could not find admin's username.")
                        }
                    })
                    //set admin view
                    if self.adminID == self.userID {
                        self.isAdmin = true
                        self.addDeleteButton.isHidden = true // eventually will turn into edit button and be false
                        self.rosterButton.isHidden = false
                        self.shelf = true
                    }
                } else {
                    print("Could not find admin linked to the event: " + String(describing: self.eventID!))
                }
            } else {
                print("Could not find users linked to the event: " + String(describing: self.eventID!))
            }
        })
    }
    
    func setLabels() {
        //Set the date, time, title, and place labels as well as description scroll view
        eventRef?.child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventDetails = snapshot.value as? Dictionary<String,String> {
                self.dateTimeLabel.text = eventDetails["date_time"]
                self.titleLabel.text = eventDetails["title"]
                self.placeLabel.text = eventDetails["place"]
                self.descLabel.text = eventDetails["desc"]
                if eventDetails["rsvp"] == "true" && !self.isAdmin {
                    self.rsvpLabel.isHidden = false
                    self.rsvpSwitch.isHidden = false
                }
                // set rsvp label and button; set addDeleteButton title
                self.userRef?.child("linked_events").child(self.eventID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let value = snapshot.value as? String {
                        if value == "rsvp" || value == "shelf" {
                            self.addDeleteButton.setTitle("x", for: .normal)
                        }
                        if value == "rsvp" {
                            self.rsvpSwitch.isOn = true
                            self.shelf = true
                        }
                    }
                })
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Set up references to the database and find the current user's ID
        ref = FIRDatabase.database().reference()
        eventRef = ref?.child("posts").child("events").child(eventID!)
        userID = FIRAuth.auth()?.currentUser?.uid
        userRef = ref?.child("users").child(userID!)
        
        //Default settings for view
        rsvpLabel.isHidden = true
        rsvpSwitch.isHidden = true
        addDeleteButton.isHidden = false
        addDeleteButton.setTitle("+", for: .normal)
        rosterButton.isHidden = true


        //Query the database
        findAdminID()
        setLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changeShelfSettings(button: Int) {
        if ((!shelf) && (!rsvp)) {
            //delete event from user's linked events and event's linked users
            userRef?.child("linked_events").child(eventID!).removeValue()
            eventRef?.child("linked_users").child(userID!).removeValue()
            addDeleteButton.setTitle("+", for: .normal)
            rsvpSwitch.isOn = false
        } else {
            switch (button) {
            case 1:
                // shelf button tapped
                if (shelf && (!rsvp)) {
                    // add event to user's shelf
                    userRef?.child("linked_events").child(eventID!).setValue("shelf")
                    addDeleteButton.setTitle("x", for: .normal)
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
                    userRef?.child("linked_events").child(eventID!).setValue("shelf")
                    eventRef?.child("linked_users").child(userID!).removeValue()
                    rsvpSwitch.isOn = false
                }
                break
            default:
                break
            }
            if (shelf && rsvp) {
                eventRef?.child("linked_users").child(userID!).setValue("rsvp")
                userRef?.child("linked_events").child(eventID!).setValue("rsvp")
                addDeleteButton.setTitle("x", for: .normal)
                rsvpSwitch.isOn = true
            }
        }
    }
    
    @IBAction func addDelButtonTapped(_ sender: Any) {
        // if user != admin
        shelf = !shelf
        changeShelfSettings(button: 1)
    }

    @IBAction func rsvpSwitchChanged(_ sender: Any) {
        rsvp = !rsvp
        changeShelfSettings(button: 2)
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
                rosterViewController.postType = "events"
            }
        }
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
