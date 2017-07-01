//
//  AkaRobot.swift
//  RobotWarsOSX
//
//  Created by Akash Nambiar on 6/28/17.
//  Copyright © 2017 Make School. All rights reserved.
//

//Arena Dimesions 768 by 1024


import Foundation

class AkaRobot: Robot{
    
    enum robotState {
        case fire, firstmove, moveAway, closeFire
    }
    
    var currentState: robotState = .firstmove
    var lastKnownPosition = CGPoint(x: 0, y: 0)
    let gunToleranceAngle = CGFloat(2.0)
    var d = true
    
    var oppHealth: Int = 20
    
    override func run() {
        
        while true {
            switch currentState{
            case .firstmove:
                performFirstMove()
                break
            case .fire:
                fire()
                break
            case .moveAway:
                runAway()
                break
            case .closeFire:
                rapidFire()
                break
            default:
                turnToCenter()
                shoot()
                break
            }
        }
    }
    
    func performFirstMove() {
        let arenaSize = arenaDimensions()
        let bodyLength = robotBodySize().width
        
        // find and turn towards closest corner
        var currentPosition = position()
        if currentPosition.y < arenaSize.height / 2 {
            if currentPosition.x < arenaSize.width/2 {
                // bottom left    (0.707106765732237, 0.707106796640858)
                turnLeft(90)
                turnGunRight(45)
            } else {
                // bottom right    (-0.707106765732237, 0.707106796640858)
                turnRight(90)
                turnGunLeft(45)
            }
        } else {
            if currentPosition.x < arenaSize.width/2 {
                // top left       (0.707106765732237, -0.707106796640858)
                turnRight(90)
                turnGunLeft(45)
            } else {
                // top right       (-0.707106765732237, -0.707106796640858)
                turnLeft(90)
                turnGunRight(45)
            }
        }
        
        // back into closest corner
        currentPosition = position()
        if currentPosition.y < arenaSize.height/2 {
            moveBack(Int(currentPosition.y - bodyLength))
        } else {
            moveBack(Int(arenaSize.height - (currentPosition.y + bodyLength)))
        }
        
        turnToCenter()
        
        currentState = .fire
    }
    
    func rapidFire() {
        shoot()
    }
    
    func fire() {
        turnToCenter()
        shoot()
    }
    
    override func gotHit() {
        currentState = .moveAway
    }
    
    override func scannedRobot(_ robot: Robot!, atPosition position: CGPoint) {
        if currentState != .moveAway {
            cancelActiveAction()
            
            lastKnownPosition = position
            currentState = .closeFire
            turnToEnemyPosition(lastKnownPosition)
        }
    }
    
    func turnToCenter() {
        if currentState != .moveAway {
            cancelActiveAction()
            
            let arenaSize = arenaDimensions()
            let angle = Int(angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: arenaSize.width/2, y: arenaSize.height/2)))
            if angle < 0 {
                turnGunLeft(abs(angle))
            } else {
                turnGunRight(angle)
            }
        }
    }
    
    func f() {
        if d == false{
            turnToCenter()
            
            currentState = .fire
            
            d = true
        }
    }
    
    func turnToEnemyPosition(_ position: CGPoint) {
        cancelActiveAction()
        
        // calculate angle between turret and enemey
        let angleBetweenTurretAndEnemy = angleBetweenGunHeadingDirectionAndWorldPosition(position)
        
        // turn if necessary
        if angleBetweenTurretAndEnemy > gunToleranceAngle {
            turnGunRight(Int(abs(angleBetweenTurretAndEnemy)))
        } else if angleBetweenTurretAndEnemy < -gunToleranceAngle {
            turnGunLeft(Int(abs(angleBetweenTurretAndEnemy)))
        }
    }
    
    override func bulletHitEnemy(at position: CGPoint) {
        oppHealth -= 1
    }
    
    func runAway() {
        
        cancelActiveAction()
        
        let arenaSize = arenaDimensions()
        let bodyLength = robotBodySize().width
        
        
        let currentPosition = position()
        if currentPosition.y < arenaSize.height / 2 {
            if currentPosition.x < arenaSize.width/2 {
                // bottom left
                moveAhead(Int(arenaSize.height - (currentPosition.y + bodyLength)))
                //               turnGunRight(45)
                //               print("1")
            } else {
                // bottom right
                moveAhead(Int(arenaSize.height - (currentPosition.y + bodyLength)))
                //               turnGunLeft(45)
                //               print("2")
            }
        } else {
            if currentPosition.x < arenaSize.width/2 {
                // top left
                moveBack(Int(currentPosition.y - bodyLength))
                //            turnGunRight(45)
                //            print("3")
            } else {
                // top right
                moveBack(Int(currentPosition.y - bodyLength))
                //              turnGunLeft(45)
                //              print("4")
            }
            
        }
        
        d = false
        
        f()
    }
    
}
