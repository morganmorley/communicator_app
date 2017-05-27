//
//  PublishedResourceViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 5/26/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class PublishedResourceViewController: UIViewController {

    var ref: FIRDatabaseReference?
    var groupID: String?
    
    @IBOutlet weak var textView: UITextView!
    
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


}
