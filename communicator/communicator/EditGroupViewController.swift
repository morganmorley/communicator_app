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
    @IBOutlet weak var descTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        if let group = groupID {
            groupRef = ref?.child("posts").child("groups").child(group)
        } else {
            groupRef = ref?.child("posts").child("groups").childByAutoId()
            groupID = groupRef!.key as String
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func savePost(_ sender: Any) {
        //Post the data to firebase
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            // gather group details
            var groupDetails = Dictionary<String,String>()
            groupDetails["title"] = titleTextField.text ?? ""
            groupDetails["desc"] = descTextField.text ?? ""
            let adminDict = [userID: "admin"]
            if let group = groupID {
                ref?.child("posts").child("groups").child(group).setValue(["details": groupDetails, "linked_users": adminDict])
                let groupDict: Dictionary<String,String> = [groupID!: "admin"]
                ref?.child("users").child(userID).child("linked_groups").setValue(groupDict)
                //Dismiss the popover
                presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResource" {
            if let composeResourceViewController = segue.destination as? ComposeResourceViewController {
                // send appropriate UID to userForLookup variable on Profile View Controller
                composeResourceViewController.groupID = groupID!
            }
        } else if segue.identifier == "goToLinkedEvents" {
            if let groupEventsViewController = segue.destination as? GroupEventsStreamViewController {
                // send along the appropriate post type (groups or events) and the postId
                groupEventsViewController.groupID = groupID!
            }
        }
    }
    
}
