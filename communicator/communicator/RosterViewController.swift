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
    var postType: String?
    var userData = [String:String]()
    var usernames = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        
        // Retrieve posts for the stream and listen for changes from the database:
        ref?.child("posts").child(postType!).child(postID!).child("linked_users").observeSingleEvent(of: .value, with: { (snapshot) in
            if let users = snapshot.value as? Dictionary<String, String> {
                for (userID, role) in users {
                    if role == "rsvp" {
                        self.ref?.child("users").child(userID).child("details").child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                            if let value = snapshot.value as? String {
                                self.userData[value] = userID
                                self.usernames.append(value)
                            }
                        })
                    }
                }
                // Reload the tableView
                self.tableView.reloadData()
            }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                // send appropriate username to userIDForLookup variable on Profile View Controller
                profileViewController.userIDForLookup = userData[((sender as? UITableViewCell)?.textLabel?.text)!]
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
