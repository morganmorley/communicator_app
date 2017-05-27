//
//  GroupStreamViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 4/23/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit

import UIKit
import FirebaseDatabase
import FirebaseAuth

class GroupStreamViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref: FIRDatabaseReference?
    var groupsRef: FIRDatabaseReference?
    
    // titles of the events to be posted to the Stream:
    var postData = [String: String]()
    var postTitles = [String] ()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        var shelf = [String: String]()
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        let userID = FIRAuth.auth()?.currentUser?.uid
        groupsRef = ref?.child("groups").child("current")
        let userRef = ref?.child("user_details").child(userID!)
        
        // post the groups that are in the stream
        userRef?.child("linked_groups").observeSingleEvent(of: .value, with: { (snapshot) in
            if let shelfGroups = snapshot.value as? Dictionary<String,String> {
                for (shelfGroupID, shelfGroupName) in shelfGroups {
                    shelf[shelfGroupName] = shelfGroupID
                }
            }
            // post all events that are in the database
            self.groupsRef?.observeSingleEvent(of: .value, with: { (snapshot) in
                if let streamGroups = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                    for (groupID, groupData) in streamGroups {
                        if let groupTitle = groupData["details"]?["title"] {
                            if shelf[groupTitle] != nil {
                                self.postData[groupTitle] = groupID
                                self.postTitles.append(groupTitle)
                                // Reload the tableView
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            })
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        cell?.textLabel?.text = postTitles[indexPath.row]
        return cell!
    }
    
    @IBAction func addGroup(_ sender: Any) {
        self.performSegue(withIdentifier: "goToEditGroup", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToGroup" {
            if let groupPublishedViewController = segue.destination as? GroupPublishedViewController {
                // send appropriate event ID to eventID variable on Event Published View Controller
                groupPublishedViewController.groupID = postData[(sender as? UITableViewCell)!.textLabel!.text! as String]
            }
        }
        if segue.identifier == "goToEditGroup" {
            if let editGroupViewController = segue.destination as? EditEventViewController {
                // send appropriate event ID to eventID variable on Event Published View Controller
                editGroupViewController.groupID = postData[(sender as? UITableViewCell)!.textLabel!.text! as String]
                editGroupViewController.fromStream = true
            }
        }
    }

}
