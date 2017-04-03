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

class StreamViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var ref: FIRDatabaseReference?
    
    // titles of the events to be posted to the Stream:
    var postData = [String: String]()
    var postTitles = [String] ()

    @IBOutlet weak var tableView: UITableView!
    
    func splitDateTime(from dateTime: String) -> Dictionary<String,String> {
        //Splits dateTime strings into discreet units for comparison
        let splitInput = dateTime.components(separatedBy: " at ")
        let date = splitInput[0].components(separatedBy: ", ")
        let monthAndDay = date[1].components(separatedBy: " ")
        let month = monthAndDay[0]
        let day = monthAndDay[1]
        let year = date[2]
        let wholeTime = splitInput[1].components(separatedBy: " ")
        var hourAndMinute = wholeTime[0].components(separatedBy: ":")
        let minute: Double = Double(hourAndMinute[1])! / 60
        var hour = ""
        if wholeTime[1] == "PM" {
            hour = String(describing: (Double(hourAndMinute[0])! + 12 + minute))
        } else {
            hour = String(describing: (Double(hourAndMinute[0])! + minute))
        }
        return ["month": month, "day": day, "year": year, "hour": hour]
    }
    
    func compareDateTime(with dateTime: String, event: String) -> Bool {
        // Checks that an event is either currently happening or has yet to happen. If not, it deletes the event from the database.
        let months = ["January": 1, "February": 2, "March": 3, "April": 4, "May": 5, "June": 6, "July": 7, "August": 8, "September": 9, "October": 10, "November": 11, "December": 12]
        let current = splitDateTime(from: DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short))
        let input = splitDateTime(from: dateTime)
        if Int(current["year"]!)! <= Int(input["year"]!)!{
            if months[current["month"]!]! <= months[input["month"]!]! {
                if Int(current["day"]!)! <= Int(input["day"]!)! {
                    if Double(current["hour"]!)! <= (Double(input["hour"]!)! + 1) {
                        return true
                    }
                }
            }
        }
        // remove post from database and all references to it
        ref?.child("posts").child("events").child(event).removeValue()
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
        // Do any additional setup after loading the view.
        // Need these to conform with UITableViewDelegate and UITableViewDataSource:
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        let userID = FIRAuth.auth()?.currentUser?.uid
        let eventsRef = ref?.child("posts").child("events")
        let userRef = ref?.child("users").child(userID!)

        // post all events that are in the database
        eventsRef?.observeSingleEvent(of: .value, with: { (snapshot) in
            if let posts = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                for (eventID, data) in posts {
                    // check date against current date incase deletion
                    if let dateTime = data["details"]?["date_time"] {
                        if self.compareDateTime(with: dateTime, event: eventID) {
                            if let eventTitle = data["details"]?["title"] {
                                self.postData[eventTitle] = eventID
                                self.postTitles.append(eventTitle)
                            }
                        }
                    }
                }
            }
        })
        
        // get rid of posts that are also in your shelf
        userRef?.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
            if let events = snapshot.value as? Dictionary<String,String> {
                for (shelfEventID, _) in events {
                    for (eventTitle, streamEventID) in self.postData {
                        if streamEventID == shelfEventID {
                            self.postData.removeValue(forKey: eventTitle)
                            func delete(element: String, list: Array<String>) -> Array<String> {
                                let newList = list.filter({ $0 != element })
                                return newList
                            }
                            self.postTitles = delete(element: eventTitle, list: self.postTitles)
                            // Reload the tableView
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        return postTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // add a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        cell?.textLabel?.text = postTitles[indexPath.row]
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEvent" {
            if let eventPublishedViewController = segue.destination as? EventPublishedViewController {
                // send appropriate event ID to eventID variable on Event Published View Controller
                eventPublishedViewController.eventID = postData[(sender as? UITableViewCell)!.textLabel!.text! as String]
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
