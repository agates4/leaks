//
//  MasterViewController.swift
//  leaks
//
//  Created by Aron Gates on 9/23/17.
//  Copyright © 2017 Aron Gates. All rights reserved.
//

import UIKit
import KeychainSwift

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var addressList = [String]()
    var nicknameList = [String]()
    var keychain = KeychainSwift()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }

        keychain.synchronizable = true
        let checkData = self.keychain.getData("addressList")
        if checkData == nil {
            let initArray:[String] = []
            let dataObject = NSKeyedArchiver.archivedData(withRootObject: initArray)
            keychain.set(dataObject, forKey: "addressList")
            keychain.set(dataObject, forKey: "nicknameList")
        }
        else {
            let dataObject = self.keychain.getData("addressList")!
            addressList = NSKeyedUnarchiver.unarchiveObject(with: dataObject) as! [String]
            
            let dataObject2 = self.keychain.getData("nicknameList")!
            nicknameList = NSKeyedUnarchiver.unarchiveObject(with: dataObject2) as! [String]
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func insertNewObject(_ sender: Any) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Add a location", message: "Let's find those leaks!", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = "Enter nickname"
        }
        alert.addTextField { (textField) in
            textField.text = "Enter address"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert!.textFields![1] // Force unwrapping because we know it exists.
            let textField2 = alert!.textFields![0]
            let defaultValue = "null"
            let userAddress = textField.text ?? defaultValue
            let userNickname = textField2.text ?? defaultValue
            
            if !self.addressList.contains(userAddress) {
                self.addressList.insert(userAddress, at: 0)
                let dataObject = NSKeyedArchiver.archivedData(withRootObject: self.addressList)
                self.keychain.set(dataObject, forKey: "addressList")
                
                self.nicknameList.insert(userNickname, at: 0)
                let dataObject2 = NSKeyedArchiver.archivedData(withRootObject: self.nicknameList)
                self.keychain.set(dataObject2, forKey: "nicknameList")
                
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = [addressList[indexPath.row], nicknameList[indexPath.row]]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                let _ = controller.view // forces view to load prior to sending segue
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addressList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = nicknameList[indexPath.row]
        let object2 = addressList[indexPath.row]
        cell.textLabel!.text = object.description
        cell.detailTextLabel!.text = object2.description
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            addressList.remove(at: indexPath.row)
            nicknameList.remove(at: indexPath.row)
            let dataObject = NSKeyedArchiver.archivedData(withRootObject: self.addressList)
            self.keychain.set(dataObject, forKey: "addressList")
            let dataObject2 = NSKeyedArchiver.archivedData(withRootObject: self.nicknameList)
            self.keychain.set(dataObject2, forKey: "nicknameList")
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

