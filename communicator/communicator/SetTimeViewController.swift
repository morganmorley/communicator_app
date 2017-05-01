//
//  SetTimeViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 4/30/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class SetTimeViewController: UIViewController {

    var isDraft: Bool?
    var eventID: String?
    var ref: FIRDatabaseReference?

    @IBOutlet weak var startDateTimeSetter: UIDatePicker!
    @IBOutlet weak var endDateTimeSetter: UIDatePicker!
    var startDateTime: String = ""
    var endDateTime: String = ""

    
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
        //TODO - save datetimes to drafts or posts from strings
        let eventDetails = ["start_date_time": startDateTime, "end_date_time": endDateTime]
        ref?.child("draft_posts").child("events").child(eventID!).setValue(eventDetails)
        self.performSegue(withIdentifier: "goToEditEvent", sender: self)
    }
    
    @IBAction func startSetterChanged(_ sender: Any) {
        //set date and time for storage
        startDateTime =  DateFormatter.localizedString(from: startDateTimeSetter.date, dateStyle:
            DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
    }
    
    @IBAction func endSetterChanged(_ sender: Any) {
        //set date and time for storage
        endDateTime =  DateFormatter.localizedString(from: endDateTimeSetter.date, dateStyle:
            DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEditEvent" {
            if let editEventViewController = segue.destination as? EditEventViewController {
                //send appropriate eventID for saving the time on Set Tiime View Controller
                editEventViewController.eventID = eventID!
                editEventViewController.isDraft = isDraft!
            }
        }
    }

}
