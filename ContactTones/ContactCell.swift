//
//  ContactCell.swift
//  ContactTones
//
//  Created by Deepak on 18/03/17.
//  Copyright © 2017 Deepak. All rights reserved.
//

import UIKit
import AVFoundation

class ContactCell: UITableViewCell {

    weak var delegate:AddContactViewController?
    @IBOutlet weak var contactImageLabel: UILabel!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var phoneNumber: UILabel!
    @IBOutlet weak var selectedButton: UIButton!
    @IBOutlet weak var playPause: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()

        let label = UILabel()
        label.text = "+"
        accessoryView?.addSubview(label)
        // Initialization code
    }

    @IBAction func playPauseButtonTapped(_ sender: Any) {
        if playPause.tag == 0 {
            playPause.setImage(UIImage(named: "stop"), for: .normal)
            playPause.tag = 1
            selectedButton.isEnabled = false
            delegate?.play(true)
        }
        else{
            playPause.setImage(UIImage(named: "play"), for: .normal)
            playPause.tag = 0
            selectedButton.isEnabled = true
            delegate?.play(false)
        }
    }

    @IBAction func recordSaveButtonTapped(_ sender: Any) {
        if selectedButton.tag == 0 {
            playPause.isEnabled = false
            selectedButton.setImage(UIImage(named: "save"), for: .normal)
            selectedButton.tag = 1
            delegate?.record(true)
        }
        else{
            playPause.isEnabled = true
            selectedButton.setImage(UIImage(named: "record"), for: .normal)
            selectedButton.tag = 0
            delegate?.record(false)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
