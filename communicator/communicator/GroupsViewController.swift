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

class GroupsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref: FIRDatabaseReference?
    var groupsRef: FIRDatabaseReference?
    
    // titles of groups to be posted to the shelf and stream:
    var groupData = [String: String]()
    var shelfTitles: [String] = []
    var streamTitles: [String] = []
    var headerTitles: [String] = []
    var groupTitles: [[String]] {
        var twoDimArray: [[String]] = []
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        groupsRef = ref?.child("groups").child("current")
        let userID = FIRAuth.auth()?.currentUser?.uid
        let userRef = ref?.child("user_details").child(userID!)
        
        // post the groups that are in the stream
        userRef?.child("linked_groups").observeSingleEvent(of: .value, with: { (snapshot) in
            if let shelfGroups = snapshot.value as? Dictionary<String,String> {
                for (shelfGroupID, shelfGroupName) in shelfGroups {
                    self.groupData[shelfGroupName] = shelfGroupID
                    self.shelfTitles.append(shelfGroupName)
                    // Reload the tableView
                    self.tableView.reloadData()
                }
            }
            // post all events that are in the database
            self.groupsRef?.observeSingleEvent(of: .value, with: { (snapshot) in
                if let streamGroups = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                    for (groupID, data) in streamGroups {
                        if let groupTitle = data["details"]?["title"] {
                            if self.groupData[groupTitle] == nil { // take shelved groups out of the stream.
                                self.groupData[groupTitle] = groupID
                                self.streamTitles.append(groupTitle)
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return groupTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if groupTitles.count == 0 { return nil }
        if groupTitles[section].count == 0 { return nil }
        if section < headerTitles.count { return headerTitles[section] }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        if numberOfSectionsInTableView(tableView: tableView) == 0 {
            return 0
        }
        return groupTitles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        cell?.textLabel?.text = groupTitles[indexPath.section][indexPath.row]
        return cell!
    }
    
    @IBAction func addGroup(_ sender: Any) {
        self.performSegue(withIdentifier: "goToEditGroup", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPublishedGroup" {
            if let groupPublishedViewController = segue.destination as? GroupPublishedViewController {
                // send appropriate group ID to groupID variable on Group Published View Controller
                groupPublishedViewController.groupID = groupData[(sender as? UITableViewCell)!.textLabel!.text! as String]
            }
        }
    }

}
