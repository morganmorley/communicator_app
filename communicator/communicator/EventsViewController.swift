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
    var nowTitles: [String] = []
    var shelfTitles: [String] = []
    var streamTitles: [String] = []
    var headerTitles: [String] = []
    var eventTitles: [[String]] {
        var twoDimArray: [[String]] = []
        if nowTitles.count > 0 {
            headerTitles.append("Happening Now")
            twoDimArray.append(nowTitles)
        }
        if shelfTitles.count > 0 {
            headerTitles.append("Shelf")
            twoDimArray.append(shelfTitles)
        }
        if streamTitles.count > 0 {
            headerTitles.append("Stream")
            twoDimArray.append(streamTitles)
        }
        return twoDimArray
    }

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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        let userID = FIRAuth.auth()?.currentUser?.uid
        eventsRef = ref?.child("events").child("current")
        let userRef = ref?.child("user_details").child(userID!)
        
        //post about events on your shelf that are happening now:
        userRef?.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
            if let shelfEvents = snapshot.value as? Dictionary<String,String> {
                //FOR ALL THE EVENTS IN YOUR SHELF
                for (shelfEventID, shelfEventName) in shelfEvents {
                    //TEST THEIR DATES
                    self.eventsRef?.child(shelfEventID).child("details").observeSingleEvent(of: .value, with: { (snapshot) in
                        if let eventDetails = snapshot.value as? Dictionary<String,String> {
                            //TO SEE IF THEIR START DATE HAS PASSED
                            if (self.stringToDate(eventDetails["start_datetime"]!) < Date() ) {
                                //IF THEIR END DATE HAS ALSO PASSED, DELETE THEM
                                if (self.stringToDate(eventDetails["end_datetime"]!) < Date()) {
                                    self.deleteEvent(shelfEventID)
                                //ELSE, ADD THEM TO THE HAPPENING NOW SECTION OF THE TABLEVIEW
                                } else {
                                    self.eventData[shelfEventName] = shelfEventID
                                    self.nowTitles.append(shelfEventName)
                                    // Reload the tableView
                                    self.tableView.reloadData()
                                }
                            //IF THEIR END DATE HAS NOT ALREADY PASSED, ADD THEM TO THE SHELF SECTION OF THE TABLEVIEW
                            } else {
                                self.eventData[shelfEventName] = shelfEventID
                                self.shelfTitles.append(shelfEventName)
                                // Reload the tableView
                                self.tableView.reloadData()
                            }
                        }
                        // post all events that are in the database in the stream section
                        self.eventsRef?.observeSingleEvent(of: .value, with: { (snapshot) in
                            if let streamEvents = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                                for (eventID, data) in streamEvents {
                                    if self.eventData[(data["details"]?["title"]!)!] == nil {
                                        if (self.stringToDate((data["details"]?["start_datetime"]!)!) < Date() ) {
                                            if (self.stringToDate((data["details"]?["end_datetime"]!)!) < Date()) {
                                                self.deleteEvent(eventID)
                                            } else {
                                                self.eventData[(data["details"]?["title"]!)!] = eventID
                                                self.streamTitles.append((data["details"]?["title"]!)!)
                                                // Reload the tableView
                                                self.tableView.reloadData()
                                            }
                                        } else {
                                            self.eventData[(data["details"]?["title"]!)!] = eventID
                                            self.streamTitles.append((data["details"]?["title"]!)!)
                                            // Reload the tableView
                                            self.tableView.reloadData()
                                        }
                                    }
                                }
                            }
                        })
                    })
                }
            }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return eventTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < headerTitles.count { return headerTitles[section] }
        return nil
    }
    
    @IBAction func addEvent(_ sender: Any) {
        self.performSegue(withIdentifier: "goToEditEvent", sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        if numberOfSectionsInTableView(tableView: tableView) == 0 {
            return 0
        }
        return eventTitles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // add a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath)
        cell.textLabel?.text = eventTitles[indexPath.section][indexPath.row]
        return cell
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
