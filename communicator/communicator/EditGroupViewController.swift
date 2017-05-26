//
//  EditGroupViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 4/23/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class EditGroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var groupID: String?
    var groupRef: FIRDatabaseReference?
    var ref: FIRDatabaseReference?
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descTextField: UITextField!
    @IBOutlet weak var addEventButton: UIButton!
    @IBOutlet weak var deleteGroupButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editResourcesButton: UIButton!
    
    var memberForLookup = ""
    var isNewEvent = false
    
    var eventData = [String: String]()
    var eventTitles = [String]()
    var memberDetails = [String: String]()
    var memberList = [String]()
    var headerTitles: [String] = []
    var tableTitles: [[String]] {
        var twoDimArray: [[String]] = []
        if eventTitles.count > 0 {
            headerTitles.append("Events")
            twoDimArray.append(eventTitles)
        }
        if eventTitles.count > 0 {
            headerTitles.append("Events")
            twoDimArray.append(eventTitles)
        }
        return twoDimArray
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        // Load details from remote source or create a new reference
        if let group = groupID {
            ref?.child("groups").child("drafts").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.hasChild(group){
                    self.ref?.child("groups").child("drafts").child(group).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? Dictionary<String,Dictionary<String,String>> {
                            self.populate(with: value)
                            self.groupRef = self.ref?.child("groups").child("drafts").child(group)
                        }
                    })
                } else {
                    self.ref?.child("groups").child("current").child(group).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? Dictionary<String,Dictionary<String,String>> {
                            self.populate(with: value)
                            self.groupRef = self.ref?.child("groups").child("current").child(group)
                        }
                    })
                }
            })
        } else {
            groupRef = ref?.child("groups").child("drafts").childByAutoId()
            groupID = groupRef!.key as String
        }
    }

    func populate(with value: [String: [String: String]]) {
        self.titleTextField.text = value["details"]?["title"] ?? ""
        self.descTextField.text = value["details"]?["desc"] ?? ""
        for (memberID, role) in value["linked_users"]! {
            self.ref?.child("user_details").child(memberID).child("details").child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                let username = snapshot.value as? String
                self.memberDetails[role + " - " + username!] = memberID
                self.memberList.append(role + " - " + username!)
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveGroup(isDraft: Bool, with segueID: String) {
        var status = ""
        if isDraft {
            status = "drafts"
        } else {
            status = "current"
        }
        //Post the data to firebase
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            // gather group details
            var groupDetails = Dictionary<String,String>()
            groupDetails["title"] = titleTextField.text ?? ""
            groupDetails["desc"] = descTextField.text ?? ""
                
            // post details to the database
            self.ref?.child("groups").child(status).child(self.groupID!).setValue(["details": groupDetails])
            self.ref?.child("groups").child(status).child(self.groupID!).child("linked_users").child(userID).setValue("admin")
            self.ref?.child("user_details").child(userID).child("linked_groups").child(self.groupID!).setValue(self.titleTextField.text ?? "")
            if !isDraft {
                //save group in promoted posts as it's published.
                let calendar = Calendar.current
                let year = String(calendar.component(.year, from: Date()))
                let postDetails = [year: [self.groupID!: ["name": self.titleTextField.text, "role": "admin"]]]
                self.ref?.child("user_profiles").child(userID).child("current").child(year).observeSingleEvent(of: .value, with: { (snapshot) in
                    if !snapshot.hasChild(self.groupID!) {
                        self.ref?.child("user_profiles").child(userID).child("possible").child(year).child(self.groupID!).setValue(postDetails)
                    } else {
                            self.ref?.child("user_profiles").child(userID).child("current").child(year).child(self.groupID!).setValue(postDetails)
                        self.ref?.child("user_profiles").child(userID).child("possible").child(year).child(self.groupID!).setValue(postDetails)
                    }
                })
                //delete draft content as its being published
                self.ref?.child("groups").child("drafts").child(self.groupID!).removeValue { (error, ref) in
                    if error != nil {
                        print("error \(String(describing: error))")
                    }
                }
                //Dismiss the popover
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "goToStream", sender: self)
            }
        }
    }
    
    @IBAction func savePost(_ sender: Any) {
        saveGroup(isDraft: false, with: "")
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        //delete any saved content in events/drafts
        self.ref?.child("groups").child("drafts").child(self.groupID!).removeValue ()
        //Dismiss the popover
        self.performSegue(withIdentifier: "goToStream", sender: self)
    }
    

    @IBAction func addEventButtonTapped(_ sender: Any) {
        isNewEvent = true
        saveGroup(isDraft: true, with: "goToEditEvent")
    }
    
    @IBAction func deleteGroupButtonTapped(_ sender: Any) {
        //delete groups from shelves
        ref?.child("user_details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let allUsers = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                for (key, details) in allUsers {
                    if (details["linked_groups"]?[self.groupID!]) != nil {
                        self.ref?.child("users").child(key).child("linked_groups").child(self.groupID!).removeValue { (error, ref) in
                            if error != nil {
                                print("error \(String(describing: error))")
                            }
                        }
                    }
                }
            }
            //delete group from groups/drafts
            self.ref?.child("groups").child("drafts").child(self.groupID!).removeValue { (error, ref) in
                if error != nil {
                    print("error \(String(describing: error))")
                }
            }
            //delete group from groups/current
            self.ref?.child("groups").child("current").child(self.groupID!).removeValue { (error, ref) in
                if error != nil {
                    print("error \(String(describing: error))")
                }
            }
            //Dismiss the popover
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        if indexPath.row < eventTitles.count   {
            saveGroup(isDraft: true, with: "goToEditEvent")
        } else {
            saveGroup(isDraft: true, with: "goToMemberProfile")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        if numberOfSectionsInTableView(tableView: tableView) == 0 {
            return 0
        }
        return tableTitles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell")
        cell?.textLabel?.text = tableTitles[indexPath.section][indexPath.row]
        return cell!
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableTitles.count == 0 { return nil }
        if tableTitles[section].count == 0 { return nil }
        if section < headerTitles.count { return headerTitles[section] }
        return nil
    }
    
    @IBAction func resourcesButtonTapped(_ sender: Any) {
        saveGroup(isDraft: true, with: "goToResources")
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        descTextField.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResources" {
            if let composeResourceViewController = segue.destination as? ComposeResourceViewController {
                // send appropriate UID to userForLookup variable on Profile View Controller
                composeResourceViewController.groupID = groupID!
            }
        } else if segue.identifier == "goToEditEvent" {
            if let eventPublishedViewController = segue.destination as? EventPublishedViewController {
                if !isNewEvent {
                    // send appropriate event ID to eventID variable on Event Published View Controller
                    eventPublishedViewController.eventID = eventData[(sender as? UITableViewCell)!.textLabel!.text! as String]
                }
            }
        } else if segue.identifier == "goToMemberProfile" {
            if let memberProfileViewController = segue.destination as? MemberProfileViewController {
                // send appropriate UID to userForLookup variable on Profile View Controller
                memberProfileViewController.userIDForLookup = memberDetails[(sender as? UITableViewCell)!.textLabel!.text! as String]
            }
        }
    }

    
}
