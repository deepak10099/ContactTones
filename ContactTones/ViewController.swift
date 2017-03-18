//
//  ViewController.swift
//  ContactTones
//
//  Created by Deepak on 18/03/17.
//  Copyright © 2017 Deepak. All rights reserved.
//


import UIKit
import Contacts
import ContactsUI

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddContactViewControllerDelegate {

    @IBOutlet weak var tblContacts: UITableView!

    var contacts = [CNContact]()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        navigationController?.navigationBar.tintColor = UIColor(red: 241.0/255.0, green: 107.0/255.0, blue: 38.0/255.0, alpha: 1.0)

        configureTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "idSegueAddContact" {
                let addContactViewController = segue.destination as! AddContactViewController
                addContactViewController.delegate = self
            }
        }
    }


    // MARK: IBAction functions

    @IBAction func addContact(_ sender: AnyObject) {
        performSegue(withIdentifier: "idSegueAddContact", sender: self)
    }


    // MARK: Custom functions

    func configureTableView() {
        tblContacts.delegate = self
        tblContacts.dataSource = self
        tblContacts.register(UINib(nibName: "ContactBirthdayCell", bundle: nil), forCellReuseIdentifier: "contactCell")
    }


    func refetchContact(contact: CNContact, atIndexPath indexPath: IndexPath) {
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                // let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactBirthdayKey, CNContactImageDataKey]
                let keys = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactEmailAddressesKey, CNContactBirthdayKey, CNContactImageDataKey] as [Any]

                do {
                    let contactRefetched = try AppDelegate.getAppDelegate().contactStore.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keys as! [CNKeyDescriptor])
                    self.contacts[indexPath.row] = contactRefetched

                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tblContacts.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                    })
                }
                catch {
                    print("Unable to refetch the contact: \(contact)", separator: "", terminator: "\n")
                }
            }
        }
    }


    func getDateStringFromComponents(_ dateComponents: DateComponents) -> String! {
        if let date = Calendar.current.date(from: dateComponents) {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.dateStyle = DateFormatter.Style.medium
            let dateString = dateFormatter.string(from: date)

            return dateString
        }

        return nil
    }



    // MARK: UITableView Delegate and Datasource functions

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell") as! ContactCell
        let currentContact = contacts[indexPath.row]

        // Set the Full Name
        cell.fullName.text = CNContactFormatter.string(from: currentContact, style: .fullName)

        //Seth the Phone Number
        cell.phoneNumber.text = String(describing: currentContact.phoneNumbers[0])

        // Set the Contact image.
        if let imageData = currentContact.imageData {
            cell.contactImage.image = UIImage(data: imageData)
        }
        
        return cell
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedContact = contacts[indexPath.row]

        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactEmailAddressesKey, CNContactBirthdayKey, CNContactImageDataKey] as [Any]

        if selectedContact.areKeysAvailable([CNContactViewController.descriptorForRequiredKeys()]) {
            let contactViewController = CNContactViewController(for: selectedContact)
            contactViewController.contactStore = AppDelegate.getAppDelegate().contactStore
            contactViewController.displayedPropertyKeys = keys
            navigationController?.pushViewController(contactViewController, animated: true)
        }
        else {
            AppDelegate.getAppDelegate().requestForAccess({ (accessGranted) -> Void in
                if accessGranted {
                    do {
                        let contactRefetched = try AppDelegate.getAppDelegate().contactStore.unifiedContact(withIdentifier: selectedContact.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])

                        DispatchQueue.main.async(execute: { () -> Void in
                            let contactViewController = CNContactViewController(for: contactRefetched)
                            contactViewController.contactStore = AppDelegate.getAppDelegate().contactStore
                            contactViewController.displayedPropertyKeys = keys
                            self.navigationController?.pushViewController(contactViewController, animated: true)
                        })
                    }
                    catch {
                        print("Unable to refetch the selected contact.", separator: "", terminator: "\n")
                    }
                }
            })
        }
    }


    // MARK: AddContactViewControllerDelegate function

    func didFetchContacts(_ contacts: [CNContact]) {
        for contact in contacts {
            self.contacts.append(contact)
        }

        tblContacts.reloadData()
    }
}



