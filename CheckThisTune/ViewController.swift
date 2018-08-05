//
//  ViewController.swift
//  CheckThisTune
//
//  Created by Daniel Vergara on 7/31/18.
//  Copyright © 2018 Daniel Vergara. All rights reserved.
//

import UIKit
import AudioKit

/* TODO
 
 Analyze percentage sharp / flat
 Transform arrow into correct position based on that.  Will need
    Current place (in radians)
    place to go (in radians)
 a way to divide radians evenly.  I should probably create a function to
 convert radians to degrees for me, and vice versa, so I do not have to worry about this myself
 and so i can work in base 10 numbers rather than using pi
 
 I also have to find a way to make the arrow stay connected to the circle, so that it does not stray when flipping, and transfering to other iOS devices.  
 */

class ViewController: UIViewController {

    
    @IBOutlet weak var semiCircle: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var sharpFlatArrow: UIImageView!
    
    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    var angleInDegrees: Double = 45.0
    
    let noteNamesWithSharps = ["A", "A♯", "B", "C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A"]
    let noteNamesWithFlats = ["A", "B♭", "B", "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A"]
    
    //Future functionality - Add a "A = x hz".
    //Then, add that to the frequency (hence the frequencies being a var and not let
    var noteFrequencies = [220.0, 233.08, 246.94, 261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392.00, 415.30, 440]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sharpFlatArrow.transform = CGAffineTransform(rotationAngle: (.pi / 4))
        semiCircle.image = UIImage(named: "semi.png")
        sharpFlatArrow.image = UIImage(named: "arrowBox.png")
        semiCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
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
        var frequency: Double = getProperFrequency(tracker.frequency)
        var position: Array<Double> = getPosition(frequency)
//        noteLabel.text = String(format: "%0.1f", frequency)
        if (position.count > 1) {
            //[low, high]
            var closest: Double = findClosestNote(position, frequency)
            position = getPosition(closest)
        }
        writeNoteName(Int(position[0]))
        animateArrow(frequency, Int(position[0]))

        noteLabel.textAlignment = .center
        noteLabel.sizeToFit()
    }
    
/*
 Function: getProperFrequency
 Purpose: Since an octave is double the frequency, I will lower the frequency to be between A220 and A440 so there will be less calculations
 Parameters:
    Double frequency - The original frequency obtained from the tracker
 Returns :
    Double newFrequency - A frequency that is between 220 and 440
Assumes:
        Frequency is > 0
 */
    func getProperFrequency(_ frequency: Double) -> Double {
        var newFrequency = frequency
        while (newFrequency > noteFrequencies[noteFrequencies.count - 1]) {
            newFrequency = newFrequency / 2
        }
        while (newFrequency < noteFrequencies[0]) {
            newFrequency = newFrequency * 2
        }
        return newFrequency
    }
    
/*
Function: getPosition
Purpose: Finds the position in your note name array that your note should be in by performing binary search on the frequency array.
Parameters:
Double frequency - The modified frequency that you will be using as a key for binary search
Returns :
     Int - An integer.  It is >= 0 if your frequency is in the array, or an integer < 0 if it is not.
Assumes:
    Array is not empty
*/
    func getPosition(_ frequency: Double) -> Array<Double> {
        //Quickly thrown together.  The general idea should be correct though.
        var start: Int = 0
        var stop: Int = noteFrequencies.count - 1
        var mid: Int = (start + stop) / 2
        var high: Double = 0.0
        var low: Double = 0.0
        while (start <= stop) {
            var value: Double = noteFrequencies[mid]
            if (frequency > value) {
                start = mid + 1
                low = noteFrequencies[mid]
                high = noteFrequencies[start]
            }
            else if (frequency < value) {
                stop = mid - 1
                low = noteFrequencies[stop]
                high = noteFrequencies[mid]
            }
            else {
                return [Double(mid)]
            }
            mid = (start + stop) / 2
        }
        //Invariant - If this point it reached, your frequency is not in the list (and therefor not in tune)
//        return -(mid + 1)
        return [low, high]
        
    }
    
    func convertDegreesToRadians(_ degree: Double) -> Double {
        //degree = degree in degrees
        return (degree * .pi / 180)
    }
    
    func writeNoteName(_ position: Int) {
        noteLabel.text = noteNamesWithFlats[position]
    }

    func findClosestNote(_ notes: Array<Double>,_ frequency: Double) -> Double {
        var low: Double = notes[0]
        var high: Double = notes[1]
        var mid: Double = (low + high) / 2
        if ( frequency < mid ) {
            return low
        }
        else {
            return high
        }
    }
    
    func animateArrow(_ frequency: Double,_ position: Int) {
        var changeInAngleInDegrees: Double = 45.0
        if (frequency != noteFrequencies[position]) {
            changeInAngleInDegrees = getDesiredAngle(frequency, position)
            var desiredAngle: Double = 45.0 + changeInAngleInDegrees
            changeInAngleInDegrees = -angleInDegrees + desiredAngle
            angleInDegrees += changeInAngleInDegrees
        }
        else {
            changeInAngleInDegrees = -angleInDegrees + 45
            angleInDegrees = 45.0
        }
//        if (desiredAngleInDegrees > 0 && desiredAngleInDegrees != 45) {
  //          desiredAngleInDegrees += 45
   //     }
 //       desiredAngleInDegrees = -angleInDegrees + desiredAngleInDegrees
//        angleInDegrees += desiredAngleInDegrees
        var angleInRadians = Float(convertDegreesToRadians(changeInAngleInDegrees))
        //Note for rotations - The concatenation is adding the angle (in radians) to the current transform matrix.  I then have to overwrite the current transform matrix with the transform matrix I have.  +.pi / 4 radians turns the item clockwise (opposite that of a unit circle)
               UIView.animate(withDuration: 0.05, animations: {
                    self.sharpFlatArrow.transform = self.sharpFlatArrow.transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(angleInRadians)))
                })
    }
    
    func getDesiredAngle(_ frequency: Double,_ position: Int) -> Double {
        var low: Double = 0.0
        var high: Double = 0.0
        var mid: Double = 0.0
        if (frequency < noteFrequencies[position]) {
            low = noteFrequencies[position - 1]
            high = noteFrequencies[position]
        }
        else if (frequency > noteFrequencies[position]) {
            low = noteFrequencies[position]
            high = noteFrequencies[position + 1]
        }
        mid = (low + high) / 2
        var midDistance: Double = abs(mid - noteFrequencies[position])
        var frequencyDistance: Double = frequency - noteFrequencies[position]
        var percentage: Double = frequencyDistance / midDistance
        return (percentage * 45)
    }
}
