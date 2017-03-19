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
import AVFoundation

protocol AddContactViewControllerDelegate {
    func didFetchContacts(_ contacts: [CNMutableContact])
}

class AddContactViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    var playBlock:((Bool) -> Void)?
    var showOnlySelectedContacts = true
    var allSelected:Bool = false
    var fetchedContacts:[CNMutableContact] = []
    var selectedContacts:[CNMutableContact] = []
    var delegate: AddContactViewControllerDelegate!
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?

    @IBOutlet weak var containerView: UIView!
    var containerheightForSelectedContactsConstraint: NSLayoutConstraint?
    var containerheightForFetchedContactsConstraint:NSLayoutConstraint?
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
        backButtonPressed(backButton)
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

    func refetchContact(contact: CNMutableContact, atIndexPath indexPath: IndexPath) {
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                let keys = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactImageDataKey, CNContactPhoneNumbersKey, CNContactNoteKey] as [Any]

                do {
                    let contactRefetched = try AppDelegate.getAppDelegate().contactStore.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keys as! [CNKeyDescriptor])
                    self.fetchedContacts[indexPath.row] = contactRefetched as! CNMutableContact

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
                let predicate = CNMutableContact.predicateForContacts(matchingName: self.searchTextField.text!)
                let keys = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactPhoneNumbersKey, CNContactImageDataKey,CNContactNoteKey] as [Any]
                var contacts = [CNMutableContact]()
                var message: String!

                let contactsStore = AppDelegate.getAppDelegate().contactStore
                do {
                    if self.searchTextField.text == ""{
                        let fetchRequest = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
                        fetchRequest.mutableObjects = true
                        try contactsStore.enumerateContacts(with: fetchRequest, usingBlock: { ( contact, stop) -> Void in
                            contacts.append(contact as! CNMutableContact)
                        })

                    }
                    else{
                        contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keys as! [CNKeyDescriptor]) as! [CNMutableContact]

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
        if showOnlySelectedContacts {
            return
        }

        let cell:ContactCell = tableView.cellForRow(at: indexPath) as! ContactCell
        let contact = fetchedContacts[indexPath.row]
        contact.note = "selected"
        self.saveContact(contact: contact )

        cell.selectedButton.titleLabel?.text = ""
        cell.selectedButton.setImage(UIImage(named: "check"), for: .normal)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if showOnlySelectedContacts {
            return
        }

        let cell:ContactCell = tableView.cellForRow(at: indexPath) as! ContactCell

        let contact = fetchedContacts[indexPath.row]
        contact.note = "notSelected"
        self.saveContact(contact: contact )

        cell.selectedButton.titleLabel?.text = "+"
        cell.selectedButton.setImage(nil, for: .normal)
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell") as! ContactCell
        cell.delegate = self
        cell.selectionStyle = .none
        var contactsArrayToDisplay:[CNMutableContact] = []
        if showOnlySelectedContacts {
            contactsArrayToDisplay = self.selectedContacts
            cell.playPause.isHidden = false
            cell.selectedButton.setImage(UIImage(named: "record"), for: .normal)
        }
        else{
            contactsArrayToDisplay = self.fetchedContacts
            let currentContact = contactsArrayToDisplay[indexPath.row]

            if currentContact.note == "selected" {
                contactsTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
                cell.selectedButton.titleLabel?.text = ""
                cell.selectedButton.setImage(UIImage(named: "check"), for: .normal)
            }
            else{
                contactsTableView.deselectRow(at: indexPath, animated: true)
                cell.selectedButton.setImage(nil, for: .normal)
                cell.selectedButton.titleLabel?.text = "+"
            }

            cell.playPause.isHidden = true
        }

        let currentContact = contactsArrayToDisplay[indexPath.row]
        let playBlock = initialisePlayBlockWithFileName(file: currentContact.identifier)
        let recordBlock = initialiseRecordBlockWithFileName(file: currentContact.identifier)

        cell.playBlock = playBlock
        cell.recordBlock = recordBlock
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

    func saveContact(contact:CNMutableContact){
        let request = CNSaveRequest()
        request.update(contact)
        do{
            try AppDelegate.getAppDelegate().contactStore.execute(request)
        } catch let error{
            print(error)
        }
    }

    func getRandomColor() -> UIColor{
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }

    func initialiseRecorder(fileName:String){
        let fileMgr = FileManager.default

        let dirPaths = fileMgr.urls(for: .documentDirectory,
                                    in: .userDomainMask)

        let soundFileURL = dirPaths[0].appendingPathComponent("\(fileName).caf")

        let recordSettings =
            [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
             AVEncoderBitRateKey: 16,
             AVNumberOfChannelsKey: 2,
             AVSampleRateKey: 44100.0] as [String : Any]

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }

        do {
            try audioRecorder = AVAudioRecorder(url: soundFileURL,
                                                settings: recordSettings as [String : AnyObject])
            audioRecorder?.prepareToRecord()
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
    }

    @IBAction func selectAllButtonTapped(_ sender: Any) {
        for index in 0..<fetchedContacts.count {
            let currentContact = fetchedContacts[index]
            if allSelected == false {
                selectAllButton.setImage(UIImage(named: "checkedBox"), for: .normal)
                currentContact.note = "selected"
            }
            else{
                selectAllButton.setImage(UIImage(named: "uncheckedBox"), for: .normal)
                currentContact.note = "unselected"
            }
            contactsTableView.reloadData()
            saveContact(contact: currentContact)
        }
        if allSelected == true {
            allSelected = false
        }
        else{
            allSelected = true
        }
    }

    @IBAction func rightItemButtonPressed(_ sender: Any) {
        if showOnlySelectedContacts {
            if let containerheightConstraint = containerheightForSelectedContactsConstraint{
                containerheightConstraint.isActive = false
            }
            containerheightForSelectedContactsConstraint = NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 140)
            containerView.addConstraint(containerheightForSelectedContactsConstraint!)
            containerView.layoutSubviews()
            selectAllContactView.isHidden = false
            contactsTableView.allowsSelectionDuringEditing = false
            contactsTableView.allowsSelection = true
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
        if let containerheightConstraint = containerheightForFetchedContactsConstraint{
            containerheightConstraint.isActive = false
        }
        containerheightForSelectedContactsConstraint = NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 90)
        containerView.addConstraint(containerheightForSelectedContactsConstraint!)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layoutSubviews()

        selectAllContactView.isHidden = true
        searchTextField.placeholder = ""
        contactsTableView.allowsSelectionDuringEditing = false
        contactsTableView.allowsSelection = false
        backButton.setImage(UIImage(named: "menu"), for: .normal)
        rightItemButton.setImage(nil, for: .normal)
        rightItemButton.titleLabel?.text = "+"
        showOnlySelectedContacts = true
        searchTextField.text = ""
        textFieldDidChange(searchTextField)
        var tempContacts:[CNMutableContact] = []
        for contact in fetchedContacts {
            if contact.note == "selected" {
                tempContacts.append(contact)
            }
        }
        selectedContacts = tempContacts
        searchTextField.text = "My contacts"
        contactsTableView.reloadData()
    }

    // MARK: AVAudioPlayerDelegate function
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        //        recordButton.isEnabled = true
        //        stopButton.isEnabled = false
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio Play Decode Error")
    }

    // MARK: AVAudioRecorderDelegate function
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Audio Record Encode Error")
    }

    func initialisePlayBlockWithFileName(file:String) -> ((Bool) -> Void) {
        let playBlock:((Bool) -> Void) = { play in
        // PLAY
        if play {
            if self.audioRecorder?.isRecording == false {
                do {
                    let fileMgr = FileManager.default
                    let dirPaths = fileMgr.urls(for: .documentDirectory,
                                                in: .userDomainMask)
                    let soundFileURL = dirPaths[0].appendingPathComponent("\(file).caf")

                    try self.audioPlayer = AVAudioPlayer(contentsOf:soundFileURL)
                    self.audioPlayer!.delegate = self
                    self.audioPlayer!.prepareToPlay()
                    self.audioPlayer!.play()
                } catch let error as NSError {
                    print("audioPlayer error: \(error.localizedDescription)")
                }
            }
        }
        else{
            //STOP
            if (self.audioRecorder?.isRecording == false) {
                self.audioPlayer?.stop()
            }
        }
        }
        return playBlock
    }

    func initialiseRecordBlockWithFileName(file:String) -> ((Bool) -> Void) {
        let recordBlock:((Bool) -> Void) = {
            record in
        //RECORD
        if record {
            self.initialiseRecorder(fileName: file)
            if self.audioRecorder?.isRecording == false {
                self.audioRecorder?.record()
            }
        }
        else{
            // STOP
            if self.audioRecorder?.isRecording == true {
                self.audioRecorder?.stop()
            }
    }
}
        return recordBlock
    }
}
