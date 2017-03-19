//
//  CreateContactViewController.swift
//  ContactTones
//
//  Created by Deepak on 18/03/17.
//  Copyright © 2017 Deepak. All rights reserved.
//


import UIKit
import Contacts

class CreateContactViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtFirstname: UITextField!

    @IBOutlet weak var txtLastname: UITextField!

    @IBOutlet weak var txtHomeEmail: UITextField!

    @IBOutlet weak var datePicker: UIDatePicker!


    override func viewDidLoad() {
        super.viewDidLoad()

        txtFirstname.delegate = self
        txtLastname.delegate = self
        txtHomeEmail.delegate = self

        let saveBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(CreateContactViewController.createContact))
        navigationItem.rightBarButtonItem = saveBarButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: Custom functions

    func createContact() {
        let newContact = CNMutableContact()

        newContact.givenName = txtFirstname.text!
        newContact.familyName = txtLastname.text!

        let homeEmail = CNLabeledValue(label: CNLabelHome, value: txtHomeEmail.text! as NSString)
        newContact.emailAddresses = [homeEmail]

        do {
            let saveRequest = CNSaveRequest()
            saveRequest.add(newContact, toContainerWithIdentifier: nil)
            try AppDelegate.getAppDelegate().contactStore.execute(saveRequest)

            navigationController?.popViewController(animated: true)
        }
        catch {
            AppDelegate.getAppDelegate().showMessage("Unable to save the new contact.")
        }
    }


    // MARK: UITextFieldDelegate functions

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
