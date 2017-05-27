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
        ref = FIRDatabase.database().reference()
        if groupID != nil {
            ref?.child("groups").child("current").child(groupID!).child("resources").observeSingleEvent(of: .value, with: { (snapshot) in
                let resources = snapshot.value as? String
                self.textView.text = resources ?? ""
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func savePost(_ sender: Any) {
        //Post the data to firebase
        let resourceText = textView.text ?? ""
        ref?.child("groups").child("drafts").child(groupID!).child("resources").setValue(resourceText)
        self.performSegue(withIdentifier: "goToEditGroup", sender: self)
    }

    @IBAction func cancelPost(_ sender: Any) {
        self.performSegue(withIdentifier: "goToEditGroup", sender: self)
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEditGroup" {
            if let editGroupViewController = segue.destination as? EditGroupViewController {
                editGroupViewController.groupID = groupID!
            }
        }
    }

}
