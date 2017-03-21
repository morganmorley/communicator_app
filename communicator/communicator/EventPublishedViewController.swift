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
    
    func setUpView() {
        // Find the UID of the admin to search for their username in users
        eventRef?.child("linked-users").observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventUsers = snapshot.value as? Dictionary<String,String> {
                for (user, role) in eventUsers {
                    if role == "admin" {
                        self.adminID = user
                    }
                }
            }
        })
        
        // set your rsvp, shelf, and admin statuses;
        userRef?.child("linked-events").child(eventID!).observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? String {
                if value == "admin" {
                    self.isAdmin = true
                } else if value == "rsvp" {
                    self.rsvp = true
                }
                self.shelf = true
            }
        })
        
        //Set the date, time, title, and place labels as well as description scroll view
        eventRef?.child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventDetails = snapshot.value as? Dictionary<String,String> {
                self.dateTimeLabel.text = eventDetails["date_time"]
                self.titleLabel.text = eventDetails["title"]
                self.placeLabel.text = eventDetails["place"]
                self.descLabel.text = eventDetails["desc"]
                if eventDetails["rsvp"] == "true" {
                    self.rsvpLabel.isHidden = false
                    self.rsvpSwitch.isHidden = false
                }
            }
        })

        //Set the admin's username
        if adminID != nil {
            ref?.child("users").child(adminID!).child("details").child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                if let value = snapshot.value as? String {
                    self.adminButton.setTitle(value, for: .normal)
                }
            })
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Set up references to the database and find the current user's ID
        ref = FIRDatabase.database().reference()
        eventRef = ref?.child("posts").child("events").child(eventID!)
        userID = FIRAuth.auth()?.currentUser?.uid
        userRef = ref?.child("users").child(userID!)

        //Query the database
        setUpView()
        
        // Hide/change buttons and labels according to user's role
        if isAdmin {
            addDeleteButton.isHidden = true // eventually will turn into edit button and be false
            rsvpLabel.isHidden = true
            rsvpSwitch.isHidden = true
            rosterButton.isHidden = false
            return
        }
        addDeleteButton.isHidden = false
        addDeleteButton.setTitle("+", for: .normal)
        rosterButton.isHidden = true
        if shelf {
            addDeleteButton.setTitle("x", for: .normal)
        }else if rsvp {
            rsvpSwitch.isOn = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addDelButtonTapped(_ sender: Any) {
        // if user != admin
        shelf = !shelf
        if !shelf {
            //delete event from your shelf
            userRef?.child("linked-events").child(eventID!).removeValue()
            return
        }
        if shelf && !rsvp {
            //put event on your shelf
            userRef?.child("linked-events").child(eventID!).setValue("shelf")
        }
    }

    @IBAction func rsvpSwitchChanged(_ sender: Any) {
        rsvp = !rsvp
        if !rsvp || (shelf && rsvp) {
            //delete event from your shelf
            eventRef?.child("linked-users").child(userID!).removeValue()
            userRef?.child("linked-events").child(eventID!).removeValue()
        }
        if !rsvp {
            //change switch and delete user from rsvp roster list
            rsvpSwitch.isOn = false
            shelf = false
        }
        if rsvp {
            //change switch and add user to rsvp roster list
            rsvpSwitch.isOn = true
            eventRef?.child("linked-users").child(userID!).setValue("rsvp")
            userRef?.child("linked-events").child(eventID!).setValue("rsvp")
            shelf = true
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
