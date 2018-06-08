//
//  RecordingViewController.swift
//  ada
//
//  Created by Heliodoro Tejedor Navarro on 6/7/18.
//  Copyright © 2018 Heliodoro Tejedor Navarro. All rights reserved.
//

import CoreData
import CoreLocation
import UIKit
import MessageUI

class RecordingViewController: UIViewController, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    @IBOutlet var buttons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.startUpdatingLocation()
        if let _ = appDelegate.emojiToSave {
            locationManager.requestLocation()
            buttonsAreEnabled = false
        } else {
            buttonsAreEnabled = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.stopUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var buttonsAreEnabled: Bool {
        get {
            return buttons[0].isEnabled
        }
        set {
            buttons.forEach { $0.isEnabled = buttonsAreEnabled }
        }
    }
    
    private func show(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onDeleteTouched(_ sender: Any) {
        let alert = UIAlertController(title: "Delete emojis", message: "Do you want to delete all the emojis recorded? You cannot undo this action", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes, delete it", style: .destructive) { action in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "EmojiRecord")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            do {
                try self.context.execute(deleteRequest)
                try self.context.save()
                self.show(message: "Deleted!")
            } catch {
                self.show(message: "It was an error, I could not delete it.")
            }
        })
        alert.addAction(UIAlertAction(title: "No, cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func save(emoji: String) -> Bool {
        let newEmojiRecord = EmojiRecord(context: context)
        newEmojiRecord.emoji = emoji
        newEmojiRecord.timestamp = Date()
        if let userLocation = userLocation {
            newEmojiRecord.hasLocation = true
            newEmojiRecord.lat = userLocation.coordinate.latitude
            newEmojiRecord.lon = userLocation.coordinate.longitude
        } else {
            newEmojiRecord.hasLocation = false
        }
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    @IBAction func onEmojiTouched(_ sender: UIButton) {
        guard let emoji = sender.titleLabel?.text else {
            return
        }
        let result = save(emoji: emoji)
        if result {
            self.show(message: "Recorded your emoji: \(emoji)")
        } else {
            self.show(message: "Ops! I could not record your emoji: \(emoji)")
        }
    }
    
    @IBAction func onSendEmailTouched(_ sender: Any) {
        guard MFMailComposeViewController.canSendMail() else {
            self.show(message: "Cannot send emails")
            return
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "EmojiRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        guard
            let values = try? context.fetch(request),
            let emojiValues = values as? [EmojiRecord]
            else {
                self.show(message: "Cannot fetch the data")
                return
        }

        let lines = emojiValues.map { "\($0.timestamp!),\($0.hasLocation),\($0.lat),\($0.lon),\($0.emoji!)" }
        let file = lines.joined(separator: "\n")

        guard let data = file.data(using: .utf8) else {
            self.show(message: "Cannot compose the message")
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setSubject("Your emojis!")
        mailComposer.setMessageBody("<h1>Do something cool!</h1>", isHTML: true)
        mailComposer.addAttachmentData(data, mimeType: "text/csv", fileName: "emojis.csv")
        self.present(mailComposer, animated: true, completion: nil)
    }
    
    //MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        buttonsAreEnabled = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            userLocation = locations[0]
            if let emojiToSave = appDelegate.emojiToSave {
                let result = save(emoji: emojiToSave)
                buttonsAreEnabled = true
                appDelegate.emojiToSave = nil
                if result {
                    self.show(message: "Recorded your emoji: \(emojiToSave)")
                } else {
                    self.show(message: "Ops! I could not record your emoji: \(emojiToSave)")
                }
            }
        }
    }

    //MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

