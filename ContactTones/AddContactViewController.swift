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

class AddContactViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    var showOnlySelectedContacts = true

    var fetchedContacts:[CNContact] = []
    var selectedContacts:[CNContact] = []
    var delegate: AddContactViewControllerDelegate!

    @IBOutlet weak var selectAllContactView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var rightItemButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!

    @IBOutlet weak var selectAllButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self

        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textFieldDidChange(searchTextField)
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
        contactsTableView.allowsMultipleSelection = true
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

    func textFieldDidChange(_ textField: UITextField) {
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                let predicate = CNContact.predicateForContacts(matchingName: self.searchTextField.text!)
                let keys = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactPhoneNumbersKey, CNContactImageDataKey] as [Any]
                var contacts = [CNContact]()
                var message: String!

                let contactsStore = AppDelegate.getAppDelegate().contactStore
                do {
                    if self.searchTextField.text == ""{
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
        if showOnlySelectedContacts {
            return selectedContacts.count
        }
        else{
            return fetchedContacts.count
        }
    }

    // MARK: UITableViewDelegate function
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell:ContactCell = tableView.cellForRow(at: indexPath) as! ContactCell
        var contactsArrayToDisplay:[CNContact] = []
        if showOnlySelectedContacts {
            contactsArrayToDisplay = self.selectedContacts
        }
        else{
            contactsArrayToDisplay = self.fetchedContacts
        }

        selectedContacts.append((contactsArrayToDisplay[indexPath.row]))
        cell.selectedButton.titleLabel?.text = ""
        cell.selectedButton.setImage(UIImage(named: "check"), for: .normal)
        view.layoutSubviews()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell:ContactCell = tableView.cellForRow(at: indexPath) as! ContactCell
        var contactsArrayToDisplay:[CNContact] = []
        if showOnlySelectedContacts {
            contactsArrayToDisplay = self.selectedContacts
        }
        else{
            contactsArrayToDisplay = self.fetchedContacts
        }

        contactsArrayToDisplay.remove(at: selectedContacts.index(of: contactsArrayToDisplay[indexPath.row])!)
        cell.selectedButton.titleLabel?.text = "+"
        cell.selectedButton.setImage(nil, for: .normal)
        view.layoutSubviews()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell") as! ContactCell
        var contactsArrayToDisplay:[CNContact] = []
        if showOnlySelectedContacts {
            contactsArrayToDisplay = self.selectedContacts
        }
        else{
            contactsArrayToDisplay = self.fetchedContacts
        }

        let currentContact = contactsArrayToDisplay[indexPath.row]


        // Set the Full Name
        cell.fullName.text = CNContactFormatter.string(from: currentContact, style: .fullName)

        //Seth the Phone Number
        if currentContact.phoneNumbers.count > 0 {
            cell.phoneNumber.text = currentContact.phoneNumbers[0].value.stringValue
        }

        // Set the Contact image.
        if let imageData = currentContact.imageData {
            cell.contactImage.isHidden = false
            cell.contactImageLabel.isHidden = true
            cell.contactImage.image = UIImage(data: imageData)
        }
        else{
            cell.contactImage.isHidden = true
            cell.contactImageLabel.isHidden = false
            cell.contactImageLabel.textColor = UIColor.white
            cell.contactImageLabel.text = String(describing: cell.fullName.text![(cell.fullName.text!.startIndex)])
            cell.contactImageLabel.backgroundColor = getRandomColor()
        }
        return cell
    }

    func getRandomColor() -> UIColor{
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)

    }
    @IBAction func selectAllButtonTapped(_ sender: Any) {
        selectAllButton.setImage(UIImage(named: "checkedBox"), for: .normal)
        for index in 0..<contactsTableView.numberOfRows(inSection: 0) {
            let cell = contactsTableView.cellForRow(at: IndexPath(row: index, section: 0))
            cell?.isSelected = true
//            contactsTableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: UITableViewScrollPosition.top)
//            cell?.setSelected(true, animated: true)
        }
    }

    @IBAction func rightItemButtonPressed(_ sender: Any) {
        if showOnlySelectedContacts {
            selectAllContactView.isHidden = false
            searchTextField.text = ""
            searchTextField.placeholder = "Search contacts"
            backButton.setImage(UIImage(named: "back"), for: .normal)
            rightItemButton.setImage(UIImage(named: "refresh"), for: .normal)
            showOnlySelectedContacts = false
            textFieldDidChange(searchTextField)
            contactsTableView.reloadData()
        }
        else{
            // Refresh the tableview
            textFieldDidChange(searchTextField)
        }
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        selectAllContactView.isHidden = true
        searchTextField.text = "My contacts"
        searchTextField.placeholder = ""
        backButton.setImage(nil, for: .normal)
        rightItemButton.setImage(nil, for: .normal)
        rightItemButton.titleLabel?.text = "+"
        showOnlySelectedContacts = true
        contactsTableView.reloadData()
    }
}
