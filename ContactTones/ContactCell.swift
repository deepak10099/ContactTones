//
//  ContactCell.swift
//  ContactTones
//
//  Created by Deepak on 18/03/17.
//  Copyright © 2017 Deepak. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {

    @IBOutlet weak var contactImageLabel: UILabel!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var phoneNumber: UILabel!
    @IBOutlet weak var selectedButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()

        let label = UILabel()
        label.text = "+"
        accessoryView?.addSubview(label)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
