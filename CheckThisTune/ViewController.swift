//
//  ViewController.swift
//  CheckThisTune
//
//  Created by Daniel Vergara on 7/31/18.
//  Copyright © 2018 Daniel Vergara. All rights reserved.
//

import UIKit
import AudioKit

class ViewController: UIViewController {
    
    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    @IBOutlet weak var noteLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        tracker = AKFrequencyTracker(mic)
        silence = AKBooster(tracker, gain: 0)
        noteLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        noteLabel.textAlignment = .center
    }

    override func viewDidAppear(_ animated: Bool) {
        AudioKit.output = silence
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        Timer.scheduledTimer(timeInterval: 0.1,
                            target: self,
                            selector:#selector(ViewController.updateUI),
                            userInfo: nil,
                            repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func updateUI() {
        var frequency: Double = tracker.frequency
        noteLabel.text = String(format: "%0.1f", frequency)
        noteLabel.textAlignment = .center
        noteLabel.sizeToFit()
    }

    
    
}

