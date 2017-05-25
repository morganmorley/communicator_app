//
//  StreamViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/12/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var ref: FIRDatabaseReference?
    var eventsRef: FIRDatabaseReference?

    // titles of events to be posted to the shelf and stream:
    var eventData = [String: String]()
    var eventTitles = [[String]]()
    let headerTitles = ["Happening Now", "Shelf", "Stream"]

    @IBOutlet weak var tableView: UITableView!
    
    func splitDateTime(from dateTime: String) -> DateComponents {
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

        return dateFromFirebase
    }
    
    func compareDateTime(with dateTime: String, event: String) -> Bool {
        // Checks that an event is either currently happening or has yet to happen. If not, it deletes the event from the database.
        let dateFromComponents = Calendar.current.date(from: splitDateTime(from: dateTime))!
        if Date() < dateFromComponents {
            return true
        }
        // remove post from database and all references to it
        ref?.child("events").child(event).removeValue()
        ref?.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            if let users = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                for (user, data) in users {
                    for (eventID, _) in data["linked_events"]! {
                        if eventID == event {
                            self.ref?.child("users").child(user).child("linked_events").child(eventID).removeValue()
                        }
                    }
                }
            }
        })
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Need these to conform with UITableViewDelegate and UITableViewDataSource:
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        let userID = FIRAuth.auth()?.currentUser?.uid
        eventsRef = ref?.child("posts").child("events")
        let userRef = ref?.child("users").child(userID!)
        
        //post about events on your shelf that are happening now:
        userRef?.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
            if let shelfEvents = snapshot.value as? Dictionary<String,String> {
                for (shelfEventID, shelfEventName) in shelfEvents {
                    //if event is happening after now
                    self.eventTitles[0].append(shelfEventName)
                    //else:
                        //self.eventTitles[1].append(shelfEventName)
                    self.eventData[shelfEventName] = shelfEventID
                    // Reload the tableView
                    self.tableView.reloadData()
                }
            }
            // post all events that are in the database
            self.eventsRef?.observeSingleEvent(of: .value, with: { (snapshot) in
                if let streamEvents = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                    for (eventID, data) in streamEvents {
                        // TODO - check date against current date incase deletion
                        //if let dateTime = data["details"]?["date_time"] {
                            //if self.compareDateTime(with: dateTime, event: eventID) {
                                if let eventTitle = data["details"]?["title"] {
                                    if self.eventData[eventTitle] == nil {  // take shelved groups out of the stream.
                                        self.eventData[eventTitle] = eventID
                                        self.eventTitles[2].append(eventTitle)
                                        // Reload the tableView
                                        self.tableView.reloadData()
                                    }
                                }
                            //}
                        //}
                    }
                }
            })
        })
        
    }

    override func didReceiveMemoryWarning() {
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return eventTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < headerTitles.count { return headerTitles[section] }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        return eventTitles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // add a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        cell?.textLabel?.text = eventTitles[indexPath.section][indexPath.row]
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEvent" {
            if let eventPublishedViewController = segue.destination as? EventPublishedViewController {
                // send appropriate event ID to eventID variable on Event Published View Controller
                eventPublishedViewController.eventID = eventData[(sender as? UITableViewCell)!.textLabel!.text! as String]
            }
        }
    }

}
