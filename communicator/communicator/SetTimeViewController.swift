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

    var eventID: String?
    var ref: FIRDatabaseReference?
    var eventRef: FIRDatabaseReference?
    
    var startDateTime: String = ""
    var endDateTime: String = ""
    
    @IBOutlet weak var startDateTimeSetter: UIDatePicker!
    @IBOutlet weak var endDateTimeSetter: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        eventRef = ref?.child("events").child("drafts").child(eventID!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func savePost(_ sender: Any) {
        eventRef?.child("details").child("start_datetime").setValue(startDateTime)
        eventRef?.child("details").child("end_datetime").setValue(endDateTime)
        self.performSegue(withIdentifier: "goToEditEvent", sender: self)
    }
    
    @IBAction func cancelPost(_ sender: Any) {
        self.performSegue(withIdentifier: "goToEditEvent", sender: self)
    }
    
    @IBAction func startSetterChanged(_ sender: Any) {
        //set date and time for storage
        startDateTime =  DateFormatter.localizedString(from: startDateTimeSetter.date, dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
    }
    
    @IBAction func endSetterChanged(_ sender: Any) {
        //set date and time for storage
        endDateTime =  DateFormatter.localizedString(from: endDateTimeSetter.date, dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.short)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEditEvent" {
            if let editEventViewController = segue.destination as? EditEventViewController {
                //send appropriate eventID for saving the time on Set Time View Controller
                editEventViewController.eventID = eventID!
            }
        }
    }

}
