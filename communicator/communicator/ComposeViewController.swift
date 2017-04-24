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

class ComposeViewController: UIViewController {
    
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
        if resourceText != "" { // checks if inserted an empty title
            ref?.child("posts").child("groups").child(groupID!).setValue(["resources": resourceText!])
        }
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
