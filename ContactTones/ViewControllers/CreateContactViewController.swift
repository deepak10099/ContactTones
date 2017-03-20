//
//  CreateContactViewController.swift
//  ContactTones
//
//  Created by Deepak on 18/03/17.
//  Copyright © 2017 Deepak. All rights reserved.
//


import UIKit
import Contacts

class CreateContactViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    var imageData:Data?
    @IBOutlet weak var txtFirstname: UITextField!
    @IBOutlet weak var txtLastname: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var pictureImageView: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        txtFirstname.delegate = self
        txtLastname.delegate = self
        phoneNumber.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: IBActions
    @IBAction func saveButtonTapped(_ sender: Any) {
        createContact()
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func selectImageButtonTapped(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .photoLibrary
        pickerController.allowsEditing = true

        present(pickerController, animated: true, completion: nil)
    }

    // MARK: Custom functions
    func createContact() {
        let newContact = CNMutableContact()

        newContact.givenName = txtFirstname.text!
        newContact.familyName = txtLastname.text!
        let phoneNumber = CNPhoneNumber(stringValue: self.phoneNumber.text!)
        let phoneNumberLabeledValue = CNLabeledValue(label: CNContactPhoneNumbersKey, value: phoneNumber)
        newContact.phoneNumbers = [phoneNumberLabeledValue]
        newContact.imageData = imageData
        do {
            let saveRequest = CNSaveRequest()
            saveRequest.add(newContact, toContainerWithIdentifier: nil)
            try AppDelegate.getAppDelegate().contactStore.execute(saveRequest)
            dismiss(animated: true, completion: nil)
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

    //MARK: UIImagePickerViewDelegate Methods
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        pictureImageView.titleLabel?.text = ""
        pictureImageView.setImage(info[UIImagePickerControllerOriginalImage] as! UIImage?, for: .normal)
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imageData = UIImagePNGRepresentation(info[UIImagePickerControllerOriginalImage] as! UIImage)
    }
}
