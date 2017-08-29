//
//  GameScene.swift
//  WhatWord
//
//  Created by Wes Ong on 2017-08-26.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import SpriteKit
import GameplayKit

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
        
        /* Set up category labels */
        categoryLabelShort = self.childNode(withName: "categoryLabelShort") as! SKLabelNode
        categoryLabelLong1 = self.childNode(withName: "categoryLabelLong1") as! SKLabelNode
        categoryLabelLong2 = self.childNode(withName: "categoryLabelLong2") as! SKLabelNode
    
        getRandomCategory()
        }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            getRandomCategory()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func getRandomCategory() {
        /* Get random category */
        let randomCategory = categoryDictionary.keys.shuffled().first!
        
        if randomCategory.contains("$") {
            
            /* Get category string components */
            let categorySplit = randomCategory.components(separatedBy: "$")
            
            /* Set long category labels */
            categoryLabelLong1.text = categorySplit[0].uppercased()
            categoryLabelLong2.text = categorySplit[1].uppercased()
            
            categoryLabelLong1.isHidden = false
            categoryLabelLong2.isHidden = false
            categoryLabelShort.isHidden = true
        }
        else {
        /* Set short category label */
        categoryLabelShort.text = randomCategory.uppercased()
            
            categoryLabelLong1.isHidden = true
            categoryLabelLong2.isHidden = true
            categoryLabelShort.isHidden = false
        }
        
        letterLabel.text = String((categoryDictionary[randomCategory]?.characters.shuffled().first)!)
    }
}
