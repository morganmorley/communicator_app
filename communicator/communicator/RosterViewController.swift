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
    var databaseHandle: FIRDatabaseHandle?
    var userData = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        
        // Retrieve posts to the stream and listen for changes:
        //var users: [String]
        //users.append((ref?.child("Users").key as! String)!)
        ref?.child("users").observe(.childAdded, with: { (snapshot) in
            // Code to execute when a child is added
            // Convert the value of the data to a string:
            let rosterPost = snapshot.value as? Dictionary<String, Any>
            let userTitle = rosterPost?["username"] as? String
            
            if let actualPost = userTitle {
                self.userData.append(actualPost)
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
        return userData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RosterCell")
        cell?.textLabel?.text = userData[indexPath.row]
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                profileViewController.userForLookup = (sender as? UITableViewCell)?.textLabel?.text ?? ""
            }
        }
    }
    
    //override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    //{
        // Instantiate SecondViewController
      //  let profileViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        
        // Set "Hello World" as a value to myStringValue
      //  profileViewController.userForLookup = (sender as? UITableViewCell)?.textLabel?.text ?? ""

      //  return true
    //}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
