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

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Need these to conform with UITableViewDelegate and UITableViewDataSource:
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database references:
        ref = FIRDatabase.database().reference()
        userID = FIRAuth.auth()?.currentUser?.uid
        if let userRef = ref?.child("users").child(userID!), let eventsRef = ref?.child("posts").child("events") {
            // post an event titles from the database and observe changes to the database
            userRef.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
                if let events = snapshot.value as? Dictionary<String,String> {
                    for (eventID, _) in events {
                        eventsRef.child(eventID).child("details").child("title").observeSingleEvent(of: .value, with: { (snapshot) in
                            if let postTitle = snapshot.value as? String {
                                self.postData[postTitle] = eventID
                                self.postTitles.append(postTitle)
                                // Reload the tableView
                                self.tableView.reloadData()

                            }
                        })
                    }

                }
            })
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell")
        cell?.textLabel?.text = postTitles[indexPath.row]
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEvent" {
            if let eventPublishedViewController = segue.destination as? EventPublishedViewController {
                // send appropriate event ID to eventID variable on Event Published View Controller
                eventPublishedViewController.eventID = postData[(sender as? UITableViewCell)?.textLabel?.text ?? ""]
            }
        } else if segue.identifier == "goToProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                // send appropriate UID to userIDForLookup variable on Profile View Controller
                profileViewController.userIDForLookup = userID!
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
