//
//  PulishedResourcesViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 5/23/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class PublishedResourcesViewController: UIViewController {

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
        // Dispose of any resources that can be recreated.
    }

}
