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


extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
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
        configureFirstVC()
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

    func textFieldDidChange(_ textField: UITextField) {
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                let predicate = CNMutableContact.predicateForContacts(matchingName: self.searchTextField.text!)
                let keys = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactPhoneNumbersKey, CNContactImageDataKey,CNContactNoteKey] as [Any]
                var contacts = [CNContact]()
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
                    var tempContactArray:[CNMutableContact] = []
                    for contact in contacts{
                        tempContactArray.append(contact.mutableCopy() as! CNMutableContact)
                    }
                    self.fetchedContacts = tempContactArray
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
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let cell:ContactCell = tableView.cellForRow(at: indexPath) as! ContactCell
            let contact = fetchedContacts[indexPath.row]
            let req = CNSaveRequest()
            let mutableContact = contact.mutableCopy() as! CNMutableContact
            req.delete(contact)

            do{
                try AppDelegate.getAppDelegate().contactStore.execute(req)
                print("Success, You deleted the user")
            } catch let e{
                print("Error = \(e)")
            }
            textFieldDidChange(searchTextField)
            contactsTableView.reloadData()
//            contactsTableView.deleteRows(at: [indexPath], with: .fade)
        default:
            return
        }
        }

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
            cell.selectedButton.isUserInteractionEnabled = true
            cell.playPause.isHidden = false
            cell.selectedButton.setImage(UIImage(named: "record"), for: .normal)
        }
        else{
            contactsArrayToDisplay = self.fetchedContacts
            let currentContact = contactsArrayToDisplay[indexPath.row]
            cell.selectedButton.isUserInteractionEnabled = false
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
            if let fullname = cell.fullName.text{
                cell.contactImageLabel.text = String(describing: cell.fullName.text![(cell.fullName.text!.startIndex)])
            }
            else{
                cell.contactImageLabel.text = "#"
            }
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
            searchTextField.text = ""
            searchTextField.placeholder = "Search contacts"
            backButton.setImage(UIImage(named: "back"), for: .normal)
            rightItemButton.setImage(UIImage(named: "refresh"), for: .normal)
            showOnlySelectedContacts = false
            textFieldDidChange(searchTextField)
            searchTextField.textColor = UIColor.black
            contactsTableView.reloadData()
            headerView.backgroundColor = UIColor.white
        }
        else{
            // Refresh the tableview
            textFieldDidChange(searchTextField)
        }
    }

    func configureFirstVC()
    {
            if let containerheightConstraint = containerheightForFetchedContactsConstraint{
                containerheightConstraint.isActive = false
            }
            containerheightForSelectedContactsConstraint = NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 90)
            containerView.addConstraint(containerheightForSelectedContactsConstraint!)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.layoutSubviews()

            selectAllContactView.isHidden = true
            searchTextField.placeholder = ""
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
            searchTextField.textColor = UIColor.white
            contactsTableView.reloadData()
            headerView.backgroundColor = UIColor(netHex:0xF9C901)
        }

    @IBAction func backButtonPressed(_ sender: Any) {
        if showOnlySelectedContacts {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "createVC")
            present(vc, animated: true, completion: nil)
        }
        else{
            configureFirstVC()
        }
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
