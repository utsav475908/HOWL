//
//  KeyboardViewController.swift
//  HOWL
//
//  Created by Daniel Clelland on 14/11/15.
//  Copyright © 2015 Daniel Clelland. All rights reserved.
//

import UIKit
import Bezzy
import MultitouchGestureRecognizer

class KeyboardViewController: UIViewController {
    
    @IBOutlet weak var keyboardView: UICollectionView?
    
    @IBOutlet weak var multitouchGestureRecognizer: MultitouchGestureRecognizer? {
        didSet {
            multitouchGestureRecognizer?.sustain = Settings.keyboardSustain.value
        }
    }
    
    @IBOutlet weak var flipButton: UIButton?
    
    @IBOutlet weak var holdButton: UIButton? {
        didSet {
            holdButton?.selected = Settings.keyboardSustain.value
        }
    }
    
    let keyboard: Keyboard = {
        if case .Phone = UIDevice.currentDevice().userInterfaceIdiom {
            return Keyboard(width: 4, height: 5, leftInterval: Settings.keyboardLeftInterval.value, rightInterval: Settings.keyboardRightInterval.value)
        } else {
            return Keyboard(width: 5, height: 5, leftInterval: Settings.keyboardLeftInterval.value, rightInterval: Settings.keyboardRightInterval.value)
        }
    }()
    
    var notes = [UITouch: (key: Key, note: SynthesizerNote)]()
    
    var mode: Mode = .Normal {
        didSet {
            reloadView()
        }
    }
    
    enum Mode {
        case Normal
        case ShowBackground
    }
    
    // MARK: - Life cycle
    
    func updateSynthesizer() {
        notes.keys.forEach { touch in
            if let key = keyForTouch(touch) {
                updateNoteForTouch(touch, withKey: key)
            } else {
                stopNoteForTouch(touch)
            }
        }
    }
    
    func reloadSynthesizer() {
        notes.keys.forEach { touch in
            if let key = keyForTouch(touch) {
                stopNoteForTouch(touch)
                playNoteForTouch(touch, withKey: key)
            } else {
                stopNoteForTouch(touch)
            }
        }
    }
    
    func reloadView() {
        keyboardView?.reloadData()
    }
    
    // MARK: - Note actions
    
    func playNoteForTouch(touch: UITouch, withKey key: Key) {
        if let note = Audio.client?.synthesizer.note(withFrequency: key.pitch.frequency) {
            Audio.client?.synthesizer.playNote(note)
            notes[touch] = (key: key, note: note)
        }
    }
    
    func updateNoteForTouch(touch: UITouch, withKey key: Key) {
        if let oldKey = notes[touch]?.key {
            if oldKey != key {
                stopNoteForTouch(touch)
                playNoteForTouch(touch, withKey: key)
            }
        } else {
            playNoteForTouch(touch, withKey: key)
        }
    }
    
    func stopNoteForTouch(touch: UITouch) {
        if let note = notes[touch]?.note {
            Audio.client?.synthesizer.stopNote(note)
            notes[touch] = nil
        }
    }
    
    // MARK: - Button events
    
    @IBAction func flipButtonTapped(button: UIButton) {
        flipViewController?.flip()
    }
    
    @IBAction func holdButtonTapped(button: UIButton) {
        Settings.keyboardSustain.value = !Settings.keyboardSustain.value
        multitouchGestureRecognizer?.sustain = Settings.keyboardSustain.value
        button.selected = Settings.keyboardSustain.value
    }
    
}

// MARK: - Collection view data source

extension KeyboardViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return keyboard.numberOfRows()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keyboard.numberOfKeysInRow(section)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("keyboardViewCell", forIndexPath: indexPath) as! KeyboardViewCell
        let layer = cell.layer as! CAShapeLayer
        
        guard let key = keyboard.keyAtIndex(indexPath.item, inRow: indexPath.section) else {
            return cell
        }
        
        layer.path = self.collectionView(collectionView, pathForCellAtIndexPath: indexPath, withKey: key).CGPath
        layer.fillColor = self.collectionView(collectionView, colorForCellAtIndexPath: indexPath, withKey: key).CGColor
        
        return cell
    }
    
    // MARK: - Private getters
    
    private func collectionView(collectionView: UICollectionView, pathForCellAtIndexPath indexPath: NSIndexPath, withKey key: Key) -> UIBezierPath {
        return key.path.makePath { make in
            make.translation(tx: -key.path.bounds.minX, ty: -key.path.bounds.minY)
            make.scale(sx: collectionView.bounds.width, sy: collectionView.bounds.height)
            make.translation(tx: collectionView.bounds.minX, ty: collectionView.bounds.minY)
        }
    }
    
    private func collectionView(collectionView: UICollectionView, colorForCellAtIndexPath indexPath: NSIndexPath, withKey key: Key) -> UIColor {
        let keyNotes = notes.values.filter { $0.key == key }
        
        let hue = CGFloat(key.pitch.note.rawValue) / 12.0
        let saturation = 1.0 - CGFloat(key.pitch.number - keyboard.centerPitch.number) / CGFloat(keyboard.centerPitch.number)
        let brightness = 1.0 - CGFloat(keyboard.centerPitch.number - key.pitch.number) / CGFloat(keyboard.centerPitch.number)
        
        if keyNotes.count > 0 {
            return UIColor.protonome_lightColor(withHue: hue, saturation: saturation, brightness: brightness)
        }
        
        if mode == .ShowBackground {
            return UIColor.protonome_darkColor(withHue: hue, saturation: saturation, brightness: brightness)
        } else {
            return UIColor.protonome_darkGrayColor()
        }
    }
    
}

// MARK: - Keyboard view layout delegate

extension KeyboardViewController: KeyboardViewLayoutDelegate {
    
    func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, pathForItemAtIndexPath indexPath: NSIndexPath) -> UIBezierPath? {
        guard let key = keyboard.keyAtIndex(indexPath.item, inRow: indexPath.section) else {
            return nil
        }
        
        return key.path.makePath { make in
            make.scale(sx: collectionView.bounds.width, sy: collectionView.bounds.height)
            make.translation(tx: collectionView.bounds.minX, ty: collectionView.bounds.minY)
        }
    }
    
}

// MARK: - Multitouch gesture recognizer delegate

extension KeyboardViewController: MultitouchGestureRecognizerDelegate {
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidBegin touch: UITouch) {
        if let key = keyForTouch(touch) {
            playNoteForTouch(touch, withKey: key)
        }
        reloadView()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidMove touch: UITouch) {
        if let key = keyForTouch(touch) {
            updateNoteForTouch(touch, withKey: key)
        } else {
            stopNoteForTouch(touch)
        }
        reloadView()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidCancel touch: UITouch) {
        stopNoteForTouch(touch)
        reloadView()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidEnd touch: UITouch) {
        stopNoteForTouch(touch)
        reloadView()
    }
    
    // MARK: Private getters
    
    private func keyForTouch(touch: UITouch) -> Key? {
        guard let keyboardView = keyboardView else {
            return nil
        }
        
        let location = touch.locationInView(keyboardView).ilerp(rect: keyboardView.bounds)
        
        return keyboard.keyAtLocation(location)
    }
    
}
