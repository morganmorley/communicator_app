//
//  ComposeViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/12/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ComposeResourceViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var ref: FIRDatabaseReference?
    var groupID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func savePost(_ sender: Any) {
        //Post the data to firebase
        let resourceText = textView.text
        if groupID != nil { // checks if inserted an empty title
            ref?.child("groups").child("drafts").child(groupID!).child("details").setValue(["resources": resourceText ?? ""])
            //Dismiss the popover
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

}
