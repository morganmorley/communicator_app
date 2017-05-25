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

class EditGroupViewController: UIViewController {
    
    //TODO - SET UP AND ENABLE TABLE VIEW
    
    var groupID: String?
    var groupRef: FIRDatabaseReference?
    var ref: FIRDatabaseReference?
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var addEventButton: UIButton!
    @IBOutlet weak var deleteGroupButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editResourcesButton: UIButton!
    
    var year = "2017" //TODO - make dynamic
    var memberForLookup = ""
    var isNewEvent = false
    var memberDetails = [String: [String: String]]()
    var memberList = [String]()
    var user = ""
    
    var eventData = [String: String]()
    var eventTitles = [String]()
    var tableTitles: [[String]] { return [memberList, eventTitles] }

    override func viewDidLoad() {
        super.viewDidLoad()
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
        self.titleTextView.text = value["details"]?["title"] ?? ""
        self.descTextView.text = value["details"]?["desc"] ?? ""
        for (memberID, role) in value["linked_users"]! {
            self.ref?.child("user_details").child(memberID).child("details").child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                let username = snapshot.value as? String
                self.memberDetails[memberID] = [username!: role]
                self.memberList.append(role + " - " + username!)
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveGroup(isDraft: Bool) {
        var status = ""
        if isDraft {
            status = "draft"
        } else {
            status = "current"
        }
        //Post the data to firebase
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            user = userID
            if let group = groupID {
                // gather group details
                var groupDetails = Dictionary<String,String>()
                groupDetails["title"] = titleTextView.text ?? ""
                groupDetails["desc"] = titleTextView.text ?? ""
                
                // post details to the database
                ref?.child("groups").child(status).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.hasChild(group){
                        self.ref?.child("groups").child(status).child(group).setValue(["details": groupDetails])
                        self.ref?.child("groups").child(status).child(group).child("linked_users").child(userID).setValue("admin")
                        self.ref?.child("user_details").child(userID).child("linked_groups").child(self.groupID!).setValue("admin")
                        if !isDraft {
                            //save group in promoted posts as it's published.
                            let calendar = Calendar.current
                            let year = String(calendar.component(.year, from: Date()))
                            let postDetails = [year: [group: ["name": self.titleTextView.text, "role": "admin"]]]
                            self.ref?.child("user_profiles").child(userID).child("hidden").child(year).observeSingleEvent(of: .value, with: { (snapshot) in
                                if !snapshot.hasChild(group) {
                                    self.ref?.child("user_profiles").child(userID).child("current").child(year).observeSingleEvent(of: .value, with: { (snapshot) in
                                        if !snapshot.hasChild(group) {
                                            self.ref?.child("user_profiles").child(userID).child("possible").child(year).child(group).setValue(postDetails)
                                        } else {
                                            self.ref?.child("user_profiles").child(userID).child("current").child(year).child(group).setValue(postDetails)
                                        }
                                    })
                                    
                                }
                            })
                        }
                    }else{
                        let adminDict = [userID: "admin"]
                        let groupDict: Dictionary<String,String> = [self.groupID!: "admin"]
                        self.ref?.child("posts").child("groups").child(group).setValue(["details": groupDetails, "linked_users": adminDict])
                        self.ref?.child("users").child(userID).child("linked_groups").setValue(groupDict)
                    }
                    if !isDraft {
                        //delete draft content as its being published
                        self.ref?.child("posts").child("groups").child("drafts").child(group).removeValue { (error, ref) in
                            if error != nil {
                                print("error \(String(describing: error))")
                            }
                        }
                        //Dismiss the popover
                        self.presentingViewController?.dismiss(animated: true, completion: nil)
                    } else {
                    }
                })
            }
        }
    }
    
    @IBAction func savePost(_ sender: Any) {
        saveGroup(isDraft: false)
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        //delete any saved content in events/drafts
        self.ref?.child("groups").child("drafts").child(self.groupID!).removeValue { (error, ref) in
            if error != nil {
                print("error \(String(describing: error))")
            }
        }
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    

    @IBAction func addEventButtonTapped(_ sender: Any) {
        isNewEvent = true
        saveGroup(isDraft: true)
        self.performSegue(withIdentifier: "goToEditEvent", sender: self)

    }
    
    @IBAction func deleteGroupButtonTapped(_ sender: Any) {
        //delete groups from shelves
        ref?.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
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
            self.performSegue(withIdentifier: "goToEditEvent", sender: self)
        } else {
            self.performSegue(withIdentifier: "goToMemberProfile", sender: self)
        }
    }
    
    @IBAction func resourcesButtonTapped(_ sender: Any) {
        saveGroup(isDraft: true)
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextView.resignFirstResponder()
        descTextView.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        saveGroup(isDraft: true)
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
            if let profileViewController = segue.destination as? ProfileViewController {
                // send appropriate UID to userForLookup variable on Profile View Controller
                profileViewController.userIDForLookup = memberDetails[user]?[(sender as? UITableViewCell)!.textLabel!.text! as String]
            }
        }
    }

    
}
