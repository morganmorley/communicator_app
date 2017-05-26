//
//  EditPromotedViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 5/25/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class EditPromotedViewController: UIViewController {

    @IBOutlet weak var hideButton: UIButton!
    @IBOutlet weak var changeVisibilityButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    var postID: String?
    
    var isPromoted = false
    var userID: String?
    var ref: FIRDatabaseReference?
    var year: String?
    var profileDetails: Dictionary<String,Dictionary<String,String>>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userID = FIRAuth.auth()?.currentUser?.uid
        ref?.child("user_profiles").child(userID!).child("current").observeSingleEvent(of: .value, with: { (snapshot) in
            if let currentData = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                for (currentYear, currentPosts) in currentData {
                    if (currentPosts[self.postID!] != nil) {
                        self.isPromoted = true
                        self.year = currentYear
                        self.changeVisibilityButton.setTitle("Unpromote", for: .normal)
                        self.profileDetails = [self.postID!: currentPosts[self.postID!]!]
                        let role: String = self.profileDetails?[self.postID!]?["role"] ?? ""
                        let postName: String = self.profileDetails?[self.postID!]?["post_name"] ?? ""
                        self.textView.text = currentYear + "\n" + role + " in " + postName
                    }
                }
            }
            if (!self.isPromoted) {
                self.ref?.child("user_profiles").child(self.userID!).child("possible").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let possibleData = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                        for (possibleYear, possiblePosts) in possibleData {
                            if (possiblePosts[self.postID!] != nil) {
                                print("gotcha")
                                self.year = possibleYear
                                self.changeVisibilityButton.setTitle("Promote", for: .normal)
                                self.profileDetails = [self.postID!: possiblePosts[self.postID!]!]
                                let role: String = self.profileDetails?[self.postID!]?["role"] ?? ""
                                let postName: String = self.profileDetails?[self.postID!]?["post_name"] ?? ""
                                self.textView.text = possibleYear + "\n" + role + " in " + postName
                                
                            }
                        }
                    }
                })
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func changeVisibilityButtonTapped(_ sender: Any) {
        self.isPromoted = !isPromoted
        if self.isPromoted {
            self.changeVisibilityButton.setTitle("Unpromote", for: .normal)
            self.ref?.child("user_profiles").child(userID!).child("current").child(year!).setValue(profileDetails)
        } else {
            self.changeVisibilityButton.setTitle("Promote", for: .normal)
            self.ref?.child("user_profiles").child(userID!).child("current").child(year!).child(postID!).removeValue()
        }
        //Dismiss the popover
        self.performSegue(withIdentifier: "goToProfile", sender: self)

    }

    @IBAction func hideOption(_ sender: Any) {
        ref?.child("user_profiles").child(userID!).child("current").child(year!).child(postID!).removeValue()
        ref?.child("user_profiles").child(userID!).child("possible").child(year!).child(postID!).removeValue()
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)

    }
}
