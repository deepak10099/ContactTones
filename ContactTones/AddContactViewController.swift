//
//  AddContactViewController.swift
//  ContactTones
//
//  Created by Deepak on 18/03/17.
//  Copyright © 2017 Deepak. All rights reserved.
//


import UIKit
import Contacts
import ContactsUI


protocol AddContactViewControllerDelegate {
    func didFetchContacts(_ contacts: [CNContact])
}

class AddContactViewController: UIViewController, UITextFieldDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    var fetchedContacts:[CNContact] = []
    var selectedContacts:[CNContact] = []
    var delegate: AddContactViewControllerDelegate!

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var contactsTableView: UITableView!


    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(AddContactViewController.performDoneItemTap))
        navigationItem.rightBarButtonItem = doneBarButtonItem
        searchBar(searchBar, textDidChange: "")
        configureTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Custom functions
    func performDoneItemTap() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.delegate.didFetchContacts(self.selectedContacts)
            var  _ = self.navigationController?.popViewController(animated: true)
        })
    }

    func configureTableView() {
        contactsTableView.delegate = self
        contactsTableView.dataSource = self
        contactsTableView.register(UINib(nibName: "ContactCell", bundle: nil), forCellReuseIdentifier: "contactCell")
    }

    func refetchContact(contact: CNContact, atIndexPath indexPath: IndexPath) {
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                let keys = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactImageDataKey, CNContactPhoneNumbersKey] as [Any]

                do {
                    let contactRefetched = try AppDelegate.getAppDelegate().contactStore.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keys as! [CNKeyDescriptor])
                    self.fetchedContacts[indexPath.row] = contactRefetched

                    DispatchQueue.main.async(execute: { () -> Void in
                        self.contactsTableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                    })
                }
                catch {
                    print("Unable to refetch the contact: \(contact)", separator: "", terminator: "\n")
                }
            }
        }
    }

    // MARK: UISearchBarDelegate function
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                let predicate = CNContact.predicateForContacts(matchingName: self.searchBar.text!)
                let keys = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactPhoneNumbersKey, CNContactImageDataKey] as [Any]
                var contacts = [CNContact]()
                var message: String!

                let contactsStore = AppDelegate.getAppDelegate().contactStore
                do {
                    if self.searchBar.text == ""{
                        let fetchRequest = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
                        try contactsStore.enumerateContacts(with: fetchRequest, usingBlock: { ( contact, stop) -> Void in
                            contacts.append(contact)
                        })

                    }
                    else{
                        contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keys as! [CNKeyDescriptor])

                    }
                    if contacts.count == 0 {
                        message = "No contacts were found matching the given name."
                    }
                }
                catch {
                    message = "Unable to fetch contacts."
                }


                if message != nil {

                }
                else {
                    self.fetchedContacts = contacts
                    self.contactsTableView.reloadData()
                }
            }
        }
    }

    // MARK: UITableViewDataSource function
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedContacts.count
    }

    // MARK: UITableViewDelegate function
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell") as! ContactCell
        let currentContact = fetchedContacts[indexPath.row]

        // Set the Full Name
        cell.fullName.text = CNContactFormatter.string(from: currentContact, style: .fullName)

        //Seth the Phone Number
        if currentContact.phoneNumbers.count > 0 {
            cell.phoneNumber.text = currentContact.phoneNumbers[0].value.stringValue
        }

        // Set the Contact image.
        if let imageData = currentContact.imageData {
            cell.contactImage.image = UIImage(data: imageData)
        }

        return cell
    }

}
