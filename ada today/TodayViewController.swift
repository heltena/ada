//
//  TodayViewController.swift
//  ada today
//
//  Created by Heliodoro Tejedor Navarro on 6/7/18.
//  Copyright © 2018 Heliodoro Tejedor Navarro. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    let emojiTranslator =
        ["☹️": "sad",
         "😐": "neutral",
         "😀": "happy"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    @IBAction func onEmojiTouched(_ sender: UIButton) {
        guard
            let emoji = sender.titleLabel?.text,
            let emojiText = emojiTranslator[emoji],
            let url = URL(string: "ada://localhost/\(emojiText)")
            else {
                return
        }
        
        self.extensionContext?.open(url) { state in
        }
    }

}
