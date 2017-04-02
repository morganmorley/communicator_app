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
                    if let eventTitle = data["details"]?["title"] {
                        self.postData[eventTitle] = eventID
                        self.postTitles.append(eventTitle)
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
