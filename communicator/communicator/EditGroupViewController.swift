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
    
    var groupID: String?
    var groupRef: FIRDatabaseReference?
    var ref: FIRDatabaseReference?
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descTextView: UITextView!
    
    var eventData = [String: String]()
    var eventTitles = [String]()
    var fromStream: Bool?
    var fromShelf: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                self.fromStream = false
                if self.fromShelf == nil { self.fromShelf = false }
            })
        } else {
            groupRef = ref?.child("groups").child("drafts").childByAutoId()
            groupID = groupRef!.key as String
            fromStream = true
            fromShelf = false
        }

    }
    
    func populate(with value: [String: [String: String]]) {
        self.titleTextField.text = value["details"]?["title"] ?? ""
        self.descTextView.text = value["details"]?["desc"] ?? ""
        for (eventID, eventName) in (value["linked_Events"])! {
            eventData[eventName] = eventID
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
            groupDetails["desc"] = descTextView.text ?? ""
            
            // post details to the database
            self.ref?.child("groups").child(status).child(self.groupID!).setValue(["details": groupDetails])
            self.ref?.child("groups").child(status).child(self.groupID!).child("linked_users").child(userID).setValue("admin")
            self.ref?.child("user_details").child(userID).child("linked_groups").child(self.groupID!).setValue(self.titleTextField.text ?? "")
            if !isDraft {
                
                //delete draft content as its being published
                self.ref?.child("groups").child("drafts").child(self.groupID!).removeValue { (error, ref) in
                    if error != nil {
                        print("error \(String(describing: error))")
                    }
                }
            }
            self.performSegue(withIdentifier: segueID, sender: self)
        }
    }

    
    @IBAction func savePost(_ sender: Any) {
        var segueID = ""
        if fromStream! {
            segueID = "goToStream"
        } else if fromShelf!{
            segueID = "goToShelf"
        } else {
            segueID = "goToPublishedGroup"
        }
        saveGroup(isDraft: false, with: segueID)
    }
    
    @IBAction func deleteGroup(_ sender: Any) {
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
    
    @IBAction func cancelPost(_ sender: Any) {
        var segueID = ""
        if fromStream! {
            segueID = "goToStream"
        } else if fromShelf!{
            segueID = "goToShelf"
        } else {
            segueID = "goToPublishedGroup"
        }
        self.ref?.child("groups").child("drafts").child(self.groupID!).removeValue ()
        self.performSegue(withIdentifier: segueID, sender: self)
    }
    
    @IBAction func resourcesButtonTapped(_ sender: Any) {
        saveGroup(isDraft: true, with: "goToResources")
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        descTextView.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResources" {
            if let composeResourceViewController = segue.destination as? ComposeResourceViewController {
                // send appropriate UID to userForLookup variable on Profile View Controller
                composeResourceViewController.groupID = groupID!
            }
        }
    }
    
}
