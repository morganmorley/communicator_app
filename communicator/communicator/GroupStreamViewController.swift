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
    
    // titles of the events to be posted to the Stream:
    var postData = [String: String]()
    var postTitles = [String] ()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        let userID = FIRAuth.auth()?.currentUser?.uid
        let groupsRef = ref?.child("posts").child("groups")
        let userRef = ref?.child("users").child(userID!)
        
        // Do any additional setup after loading the view.
        
        // post all events that are in the database
        groupsRef?.observeSingleEvent(of: .value, with: { (snapshot) in
            if let posts = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                for (groupID, data) in posts {
                    if let groupTitle = data["details"]?["title"] {
                        self.postData[groupTitle] = groupID
                        self.postTitles.append(groupTitle)
                    }
                }
            }
        })
        
        // get rid of posts that are also in your shelf
        userRef?.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
            if let groups = snapshot.value as? Dictionary<String,String> {
                for (shelfGroupID, _) in groups {
                    for (groupTitle, streamGroupID) in self.postData {
                        if streamGroupID == shelfGroupID {
                            self.postData.removeValue(forKey: groupTitle)
                            func delete(element: String, list: Array<String>) -> Array<String> {
                                let newList = list.filter({ $0 != element })
                                return newList
                            }
                            self.postTitles = delete(element: groupTitle, list: self.postTitles)
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
        if segue.identifier == "goToGroup" {
            if let groupPublishedViewController = segue.destination as? GroupPublishedViewController {
                // send appropriate event ID to eventID variable on Event Published View Controller
                groupPublishedViewController.groupID = postData[(sender as? UITableViewCell)!.textLabel!.text! as String]
            }
        }
    }

}
