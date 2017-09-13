//
//  GameScene.swift
//  WhatWord
//
//  Created by Wes Ong on 2017-08-26.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import SpriteKit
import GameplayKit
import AudioToolbox
import AVFoundation

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

class GameScene: SKScene {
    
    /* Initialize category dictionary */
    var categoryDictionary: [String:String] = [:]
    
    /* Initialize game elements */
    var letterLabel: SKLabelNode!
    var categoryLabelShort: SKLabelNode! // For short category names
    var categoryLabelLong1: SKLabelNode! // For long category names
    var categoryLabelLong2: SKLabelNode! // For long category names
    var iTop: SKSpriteNode! // For letter I
    var iBottom: SKSpriteNode! // For letter I
    var timerOn: Bool = false
    
    /* Initialize game over elements */
    /* Initialize menu elements */
    var gameOverTopBackground: SKSpriteNode!
    var gameOverBottomBackground: SKSpriteNode!
    var gameOverBanner: SKSpriteNode!
    var restartButton: MSButtonNode!
    var homeButton: MSButtonNode!
    
    
    /* Label/var to track start timer */
    var startTimerLabel: SKLabelNode!
    var startTime: Int = 0 {
        didSet {
            
            /* Set minimum time */
            if startTime < 3 {
                startTime = 3
            }
            
            /* Set maximum time */
            if startTime > 10 {
                startTime = 10
            }
            
            /* Update label */
            self.startTimerLabel.text = String(self.startTime)
        }
    }
    
    /* Label/var to track game timer */
    var gameTimerLabel: SKLabelNode!
    var gameTime: Int = 0 {
        didSet {
            /* Update label */
            self.gameTimerLabel.text = String(self.gameTime)
        }
    }
    var maxGameTime: Int!
    
    /* Initialize menu elements */
    var titleTopBackground: SKSpriteNode!
    var titleBottomBackground: SKSpriteNode!
    var playBanner: MSButtonNode!
    var decreaseButton: MSButtonNode!
    var increaseButton: MSButtonNode!
    
    
    /* Initialize movement actions */
    let moveRightAction: SKAction = SKAction.moveTo(x: 320, duration: 1)
    let moveLeftAction: SKAction = SKAction.moveTo(x: -320, duration: 1)
    let resetAction: SKAction = SKAction.moveTo(x: 0, duration: 0.5)
    
    /* Initialize sound elements */
    var player: AVAudioPlayer?
    var tickPlayer: AVAudioPlayer?
    
    override func didMove(to view: SKView) {
        
        /* Disable multitouch */
        self.view?.isMultipleTouchEnabled = false
        
        /* Read plist file */
        if let url = Bundle.main.url(forResource:"Categories", withExtension: "plist") {
            do {
                let data = try Data(contentsOf: url)
                
                categoryDictionary = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String:String]
                
            }
            catch {
                print(error)
            }
        }
        
        /* Set up letter label */
        letterLabel = self.childNode(withName: "letterLabel") as! SKLabelNode
        iTop = self.childNode(withName: "iTop") as! SKSpriteNode
        iBottom = self.childNode(withName: "iBottom") as! SKSpriteNode
        
        /* Set up category labels */
        categoryLabelShort = self.childNode(withName: "categoryLabelShort") as! SKLabelNode
        categoryLabelLong1 = self.childNode(withName: "categoryLabelLong1") as! SKLabelNode
        categoryLabelLong2 = self.childNode(withName: "categoryLabelLong2") as! SKLabelNode
        
        /* Set up game timer */
        gameTimerLabel = self.childNode(withName: "gameTimerLabel") as! SKLabelNode
        
        /* Set up main menu elements */
        titleTopBackground = self.childNode(withName: "titleTopBackground") as! SKSpriteNode
        titleBottomBackground = self.childNode(withName: "titleBottomBackground") as! SKSpriteNode
        playBanner = self.childNode(withName: "playBanner") as! MSButtonNode
        startTimerLabel = titleBottomBackground.childNode(withName: "startTimerLabel") as! SKLabelNode
        decreaseButton = titleBottomBackground.childNode(withName: "decreaseButton") as! MSButtonNode
        increaseButton = titleBottomBackground.childNode(withName: "increaseButton") as! MSButtonNode
        
        /* Set default start time */
        startTime = 5
        
        moveRightAction.timingMode = .easeIn
        moveLeftAction.timingMode = .easeIn
        resetAction.timingMode = .easeIn
        
        /* Disable touches */
        self.isUserInteractionEnabled = false
        
        /* Set play button handler */
        playBanner.selectedHandler = { [unowned self] in
            
            self.playTicking()
            
            /* Prevent multiple taps on button */
            self.playBanner.state = .msButtonNodeStateInactive
            
            /* Play animation */
            self.titleTopBackground.run(self.moveLeftAction)
            self.titleBottomBackground.run(self.moveLeftAction)
            
            self.playBanner.run(self.moveRightAction) {
                
                /* Display category */
                self.getRandomCategory()

                /* Enable touches */
                self.isUserInteractionEnabled = true
                
                /* Display game time */
                self.maxGameTime = self.startTime
                self.gameTime = self.maxGameTime
                self.gameTimerLabel.isHidden = false
                
                /* Start game timer */
                self.timerOn = true
                
                /* Re-enable taps */
                self.playBanner.state = .msButtonNodeStateActive
            }
        }
        
        /* Set increase/decrease button handler */
        increaseButton.selectedHandler = { [unowned self] in
            self.startTime += 1
            self.increaseButton.state = .msButtonNodeStateActive
        }
        
        decreaseButton.selectedHandler = { [unowned self] in
            self.startTime -= 1
            self.increaseButton.state = .msButtonNodeStateActive
        }
        
        /* Set up game over elements */
        gameOverTopBackground = self.childNode(withName: "gameOverTopBackground") as! SKSpriteNode
        gameOverBottomBackground = self.childNode(withName: "gameOverBottomBackground") as! SKSpriteNode
        gameOverBanner = self.childNode(withName: "gameOverBanner") as! SKSpriteNode
        restartButton = gameOverBottomBackground.childNode(withName: "restartButton") as! MSButtonNode
        homeButton = gameOverTopBackground.childNode(withName: "homeButton") as! MSButtonNode
        
        /* Set restart button handler */
        restartButton.selectedHandler = { [unowned self] in
            
            self.playTicking()
            
            /* Disable home button */
            self.homeButton.isUserInteractionEnabled = false
            
            /* Play animation */
            self.gameOverTopBackground.run(self.moveRightAction)
            self.gameOverBottomBackground.run(self.moveRightAction)
            
            self.gameOverBanner.run(self.moveLeftAction) {
                
                /* Display category */
                self.getRandomCategory()
                
                /* Enable touches */
                self.isUserInteractionEnabled = true
                
                /* Display game time */
                self.maxGameTime = self.startTime
                self.gameTime = self.maxGameTime
                self.gameTimerLabel.isHidden = false
                
                /* Start game timer */
                self.timerOn = true
                
                /* Re-enable taps */
                self.restartButton.state = .msButtonNodeStateActive
                self.homeButton.isUserInteractionEnabled = true
            }
        }

        homeButton.selectedHandler = { [unowned self] in
            
            /* Disable restart button */
            self.restartButton.isUserInteractionEnabled = false
            
            /* Play animation */
            self.titleTopBackground.run(self.resetAction)
            self.titleBottomBackground.run(self.resetAction)
            
            self.playBanner.run(self.resetAction) { [unowned self] in
                
                /* Hide game over screen */
                self.gameOverTopBackground.isHidden = true
                self.gameOverBottomBackground.isHidden = true
                self.gameOverBanner.isHidden = true
                
                /* Reset game over screen */
                self.gameOverTopBackground.run(self.moveRightAction)
                self.gameOverBottomBackground.run(self.moveRightAction)
                self.gameOverBanner.run(self.moveLeftAction) {
                    
                    /* Show game over screen elements */
                    self.gameOverTopBackground.isHidden = false
                    self.gameOverBottomBackground.isHidden = false
                    self.gameOverBanner.isHidden = false
                }
                
                /* Hide/reset labels */
                self.categoryLabelLong1.isHidden = true
                self.categoryLabelLong2.isHidden = true
                self.categoryLabelShort.isHidden = true
                self.letterLabel.text = ""
                self.iTop.isHidden = true
                self.iBottom.isHidden = true
                self.gameTimerLabel.isHidden = true
                
                /* Disable touches */
                self.isUserInteractionEnabled = false
                
                /* Enable play button */
                self.playBanner.state = .msButtonNodeStateActive
                
                /* Re-enable taps */
                self.homeButton.state = .msButtonNodeStateActive
                self.restartButton.isUserInteractionEnabled = true
            }

        }

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        getRandomCategory()
        
        /* Reset game timer appearance */
        gameTimerLabel.removeAllActions()
        gameTimerLabel.setScale(1)
        gameTimerLabel.alpha = 1
        
        /* Set game timer value */
        gameTime = maxGameTime
        
        /* Play audio */
        playSound(soundName: "correct")
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        /* Check if game started */
        if timerOn {
        
            
            if !gameTimerLabel.hasActions(){
                
                /* Run animation and decrement timer */
                gameTimerLabel.run(SKAction(named: "Pulse")!) { [unowned self] in
                    self.gameTime -= 1
                }
            }
            
            if gameTime <= 0 {
                
                /* Turn off game timer */
                timerOn = false
                
                runGameOver()
            }
        }
    }
    
    func getRandomCategory() {
        
        var randomCategory: String!
        var newCategory: Bool = false
        
        while !newCategory {
            
            /* Get random category */
            randomCategory = categoryDictionary.keys.shuffled().first!
            
            if randomCategory.contains("$") {
                
                /* Get category string components */
                let categorySplit = randomCategory.components(separatedBy: "$")
                
                /* Make sure generated random category is different than current category */
                if (categoryLabelLong1.text != categorySplit[0].uppercased() && categoryLabelLong2.text != categorySplit[1].uppercased()) || categoryLabelLong1.isHidden {
                    
                    /* Set long category labels */
                    categoryLabelLong1.text = categorySplit[0].uppercased()
                    categoryLabelLong2.text = categorySplit[1].uppercased()
                    
                    /* Reveal label */
                    categoryLabelLong1.isHidden = false
                    categoryLabelLong2.isHidden = false
                    categoryLabelShort.isHidden = true
                    
                    /* Set Bool */
                    newCategory = true
                }
            }
            else if categoryLabelShort.text != randomCategory.uppercased() || categoryLabelShort.isHidden {
                
                /* Set short category label */
                categoryLabelShort.text = randomCategory.uppercased()
                
                /* Reveal label */
                categoryLabelLong1.isHidden = true
                categoryLabelLong2.isHidden = true
                categoryLabelShort.isHidden = false
                
                /* Set Bool */
                newCategory = true
            }
        }
        
        
        var randLetter = String((categoryDictionary[randomCategory]?.characters.shuffled().first)!)
        
        /* Make sure generated random letter is different than current letter */
        while randLetter == letterLabel.text {
            randLetter = String((categoryDictionary[randomCategory]?.characters.shuffled().first)!)
        }
    
        if randLetter == "I" {
            iTop.isHidden = false
            iBottom.isHidden = false
        }
        else {
            iTop.isHidden = true
            iBottom.isHidden = true
        }
        letterLabel.text = randLetter
    }
    
    func runGameOver() {
        
        /* Vibrate phone */
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        /* Play audio */
        playSound(soundName: "wrong")
        tickPlayer?.stop()
        
        /* Disable touches */
        self.isUserInteractionEnabled = false
        self.restartButton.isUserInteractionEnabled = false
        self.homeButton.isUserInteractionEnabled = false
        
        /* Play animation */
        gameOverTopBackground.run(resetAction)
        gameOverBottomBackground.run(resetAction)
        
        gameOverBanner.run(resetAction) { [unowned self] in
            
            /* Hide/reset labels */
            self.categoryLabelLong1.isHidden = true
            self.categoryLabelLong2.isHidden = true
            self.categoryLabelShort.isHidden = true
            self.letterLabel.text = ""
            self.iTop.isHidden = true
            self.iBottom.isHidden = true
            self.gameTimerLabel.isHidden = true
            
            /* Enable restart and home button */
            self.restartButton.isUserInteractionEnabled = true
            self.homeButton.isUserInteractionEnabled = true
        }
    }
    
    func playSound(soundName: String) {
        guard let sound = NSDataAsset(name: soundName) else {
            print("asset not found")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(data: sound.data, fileTypeHint: AVFileTypeMPEGLayer3)
            
            player!.play()
            
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func playTicking() {
        guard let sound = NSDataAsset(name: "ticktock") else {
            print("asset not found")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            tickPlayer = try AVAudioPlayer(data: sound.data, fileTypeHint: AVFileTypeMPEGLayer3)
            tickPlayer!.numberOfLoops = -1
            tickPlayer!.play()
            
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }

}
