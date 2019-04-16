//
//  VideoOptionsViewController.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 26/10/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

class VideoSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet private weak var tableView: UITableView!
    private let model: VideoSettingsViewModel = VideoSettingsViewModel()
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func dismissAction(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.numberOfItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = model.itemFor(indexPath.row)
//        switch item.type {
//        case <#pattern#>:
//            <#code#>
//        default:
//            <#code#>
//        }
        
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "blah")
        cell.textLabel?.text = "Title"
        cell.detailTextLabel?.text = "Detail"
        cell.accessoryType = .checkmark
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
