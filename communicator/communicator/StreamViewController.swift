//
//  StreamViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/12/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase

class StreamViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var ref: FIRDatabaseReference?
    var databaseHandle: FIRDatabaseHandle?
    
    // titles of the events to be posted to the Stream:
    var postData = [String]()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Need these to conform with UITableViewDelegate and UITableViewDataSource:
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set the firebase database reference:
        ref = FIRDatabase.database().reference()
        
        // Retrieve posts to the stream and listen for changes:
        let eventsRef = ref?.child("posts").child("events")
        // post an event title from the database and observe changes to the database
        eventsRef?.observe(.childAdded, with: { (snapshot) in
            let post = snapshot.value as? Dictionary<String, Any>
            let eventTitle = post?["title"] as? String
            if let actualPost = eventTitle {
                self.postData.append(actualPost)
                // Reload the tableView
                self.tableView.reloadData()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        return postData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // add a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        cell?.textLabel?.text = postData[indexPath.row]
        return cell!
    }

    //TODO - Do I need this?
    @IBOutlet weak var rosterButton: UITabBarItem!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
