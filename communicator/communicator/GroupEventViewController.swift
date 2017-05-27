//
//  GroupEventViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 5/26/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class GroupEventViewController: UIViewController {
    
    var ref: FIRDatabaseReference?
    var eventRef: FIRDatabaseReference?
    var userRef: FIRDatabaseReference?
    var eventID: String?
    var userID: String?
    var adminID: String?
    
    var isAdmin: Bool = false
    var shelf: Bool = false
    var rsvp: Bool = false
    
    @IBOutlet weak var shelfEditButton: UIBarButtonItem!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var locationTextView: UITextView!
    @IBOutlet weak var rsvpButton: UIButton!
    @IBOutlet weak var adminButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startDateTime: UILabel!
    @IBOutlet weak var endDateTime: UILabel!
    
    
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
                    if self.adminID == self.userID {
                        self.isAdmin = true
                        self.rsvpButton.setTitle("RSVP List",for: .normal)
                        self.rsvpButton.isHidden = false
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
    
    func setLabels() {
        //Set the date, time, title, and place labels as well as description scroll view
        eventRef?.child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventDetails = snapshot.value as? Dictionary<String,String> {
                self.startDateTime.text = eventDetails["start_datetime"]!
                self.endDateTime.text = eventDetails["end_datetime"]!
                self.titleLabel.text = eventDetails["title"]!
                self.locationTextView.text = eventDetails["location"]!
                self.descTextView.text = eventDetails["desc"]!
                if (eventDetails["rsvp"]! == "true") {
                    self.rsvpButton.isHidden = false
                }
                if !self.isAdmin {
                    self.rsvpButton.setTitle("RSVP", for: .normal)
                    self.rsvpButton.isHidden = true
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
        eventRef = ref?.child("posts").child("events").child(eventID!)
        userID = FIRAuth.auth()?.currentUser?.uid
        userRef = ref?.child("users").child(userID!)
        
        //Default settings for view
        shelfEditButton.title = "Shelf"
        rsvpButton.isHidden = true
        
        
        //Query the database
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
                    userRef?.child("linked_events").child(eventID!).setValue(titleLabel.text)
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
                    userRef?.child("linked_events").child(eventID!).setValue(titleLabel.text as? String ?? "")
                    eventRef?.child("linked_users").child(userID!).removeValue()
                    rsvpButton.setTitle("RSVP", for: .normal)
                }
                break
            default:
                break
            }
            if (shelf && rsvp) {
                eventRef?.child("linked_users").child(userID!).setValue("rsvp")
                userRef?.child("linked_events").child(eventID!).setValue(titleLabel.text as? String ?? "")
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
                profileViewController.userID = adminID!
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
