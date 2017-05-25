//
//  RosterViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/13/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase

class RosterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref: FIRDatabaseReference?
    var postID: String?
    var userData = [String:String]()
    var usernames = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        
        // Retrieve usernames and userIDs:
        if let eventID = postID {
            ref?.child("events").child("current").child(eventID).child("linked_users").observeSingleEvent(of: .value, with: { (snapshot) in
                if let users = snapshot.value as? Dictionary<String, String> {
                    for (userID, role) in users {
                        if role == "rsvp" {
                            self.ref?.child("user_details").child(userID).child("details").child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                                if let username = snapshot.value as? String {
                                    self.userData[username] = userID
                                    self.usernames.append(username)
                                    // Reload the tableView
                                    self.tableView.reloadData()
                                }
                            })
                        }
                    }
                }
            })
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        return usernames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // add a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "RosterCell")
        cell?.textLabel?.text = usernames[indexPath.row]
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                // send appropriate user ID to userIDForLookup variable on Profile View Controller
                profileViewController.userIDForLookup = userData[((sender as? UITableViewCell)?.textLabel?.text)!]
            }
        }
    }

}
