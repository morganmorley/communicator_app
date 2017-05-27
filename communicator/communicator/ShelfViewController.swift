//
//  ShelfViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/20/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ShelfViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref: FIRDatabaseReference?
    var userID: String?
    
    // titles of the events to be posted to the Shelf:
    var postData = [String: String]()
    var postTitles: [String] = []

    var numberGroups: Int = 0

    @IBOutlet weak var tableView: UITableView!
    
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
            dateFromFirebase.hour = Int(hourAndMinute[0])! + 12
        } else {
            dateFromFirebase.hour = Int(hourAndMinute[0])!
        }
        dateFromFirebase.minute = Int(hourAndMinute[1])
        
        //Turn back into date and return
        let dateFromComponents = Calendar.current.date(from: dateFromFirebase)!
        return dateFromComponents
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Need these to conform with UITableViewDelegate and UITableViewDataSource:
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database references:
        ref = FIRDatabase.database().reference()
        userID = FIRAuth.auth()?.currentUser?.uid
        
        if let userRef = ref?.child("user_details").child(userID!), let eventsRef = ref?.child("posts").child("events") {
            // post the groups that are in the stream
            userRef.child("linked_groups").observeSingleEvent(of: .value, with: { (snapshot) in
                if let shelfGroups = snapshot.value as? Dictionary<String,String> {
                    for (shelfGroupID, shelfGroupName) in shelfGroups {
                        self.postData[shelfGroupName] = shelfGroupID
                        self.postTitles.append(shelfGroupName)
                        self.numberGroups += 1
                        // Reload the tableView
                        self.tableView.reloadData()
                    }
                }
                //post about events on your shelf that are happening now:
                userRef.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let shelfEvents = snapshot.value as? Dictionary<String,String> {
                        //FOR ALL THE EVENTS IN YOUR SHELF
                        for (shelfEventID, shelfEventName) in shelfEvents {
                            //TEST THEIR DATES
                            self.ref?.child("events").child(shelfEventID).child("details").observeSingleEvent(of: .value, with: { (snapshot) in
                                if let eventDetails = snapshot.value as? Dictionary<String,String> {
                                    //TO SEE IF THEIR START DATE HAS PASSED
                                    if (self.stringToDate(eventDetails["start_datetime"]!) < Date() ) {
                                        //IF THEIR END DATE HAS ALSO PASSED, DELETE THEM
                                        if (self.stringToDate(eventDetails["end_datetime"]!) < Date()) {
                                            self.deleteEvent(shelfEventID)
                                        } else {
                                            self.postData[(eventDetails["title"]!)] = shelfEventID
                                            self.postTitles.append((eventDetails["title"]!))
                                            // Reload the tableView
                                            self.tableView.reloadData()
                                        }
                                    } else {
                                        self.postData[(eventDetails["title"]!)] = shelfEventID
                                        self.postTitles.append((eventDetails["title"]!))
                                        // Reload the tableView
                                        self.tableView.reloadData()
                                    }
                                }
                            })
                        }
                    }
                })
            })
        }
    }
    
    func deleteEvent(_ event: String) {
        // remove post from database and all functional references to it
        ref?.child("events").child("current").child(event).removeValue()
        ref?.child("user_details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let users = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                for (user, data) in users {
                    if data["linked_events"] != nil {
                        for (eventID, _) in data["linked_events"]! {
                            if eventID == event {
                                self.ref?.child("user_details").child(user).child("linked_events").child(eventID).removeValue()
                            }
                        }
                    }
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        return postTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // add a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell")
        cell?.textLabel?.text = postTitles[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < numberGroups {
            self.performSegue(withIdentifier: "goToGroup", sender: self)
        } else {
            self.performSegue(withIdentifier: "goToEvent", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToGroup" {
            if let groupPublishedViewController = segue.destination as? GroupPublishedViewController {
                // send appropriate event ID to eventID variable on Event Published View Controller
                groupPublishedViewController.groupID = postData[(sender as? UITableViewCell)?.textLabel?.text ?? ""]
            }
        }
        if segue.identifier == "goToEvent" {
            if let eventPublishedViewController = segue.destination as? EventPublishedViewController {
                // send appropriate event ID to eventID variable on Event Published View Controller
                eventPublishedViewController.eventID = postData[(sender as? UITableViewCell)?.textLabel?.text ?? ""]
            }
        }
    }

}
