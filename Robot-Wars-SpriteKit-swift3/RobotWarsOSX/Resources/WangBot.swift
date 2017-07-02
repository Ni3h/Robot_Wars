//
//  WangBot.swift
//  RobotWar
//
//  Created by Glenn Chen on June 28th 2017.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation

class WangBot: Robot {
    
    enum RobotState {                    // enum for keeping track of RobotState
        case firstMove, camping, firing, turnaround
    }
    
    var currentRobotState: RobotState = .firstMove
    
    var lastKnownPosition = CGPoint(x: 0, y: 0)
    var lastKnownPositionTimestamp = CGFloat(0.0)
    let firingTimeout = CGFloat(1.0)
    let gunToleranceAngle = CGFloat(2.0)
    
    override func run() {
        while true {
            switch currentRobotState {
            case .firstMove:
                performFirstMoveAction()
            case .camping:
                performNextCampingAction()
            case .firing:
                performNextFiringAction()
            case .turnaround:
                break;
            }
        }
    }
    
    func performFirstMoveAction() {
        let arenaSize = arenaDimensions()
        let bodyLength = robotBodySize().width
        
        // find and turn towards closest corner
        var currentPosition = position()
        if currentPosition.y < arenaSize.height / 2 {
            if currentPosition.x < arenaSize.width/2 {
                // bottom left
                turnLeft(90)
            } else {
                // bottom right
                turnRight(90)
            }
        } else {
            if currentPosition.x < arenaSize.width/2 {
                // top left
                turnRight(90)
            } else {
                // top right
                turnLeft(90)
            }
        }
        
        // back into closest corner
        currentPosition = position()
        if currentPosition.y < arenaSize.height/2 {
            moveBack(Int(currentPosition.y - bodyLength))
        } else {
            moveBack(Int(arenaSize.height - (currentPosition.y + bodyLength)))
        }
        
        // turn gun towards wall
        turnToWall()
        currentRobotState = .camping
    }
    
    func performNextCampingAction() {
     /*   if abs(position().y - arenaDimensions().width) < 100 {
            turnLeft(180)
        }*/
        moveAhead(35)
        shoot()
    }
    
    func performNextFiringAction() {
        if currentTimestamp() - lastKnownPositionTimestamp > firingTimeout {
            turnToWall()
            currentRobotState = .camping
        } else {
            turnToEnemyPosition(lastKnownPosition)
        }
        shoot()
    }
    
    func turnToWall() {
        let arenaSize = arenaDimensions()
        var angle = 0
        if position().x < arenaSize.width / 2 {
            angle = Int(angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: arenaSize.width, y: position().y)))
        }
        else {
            angle = Int(angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: 0, y: position().y)))
        }
        
        if angle < 0 {
            turnGunLeft(abs(angle))
        } else {
            turnGunRight(angle)
        }
    }
    
    override func scannedRobot(_ robot: Robot!, atPosition position: CGPoint) {
        if currentRobotState != .firing {
            cancelActiveAction()
        }
        
        lastKnownPosition = position
        lastKnownPositionTimestamp = currentTimestamp()
        currentRobotState = .firing
    }
    
    override func gotHit() {
        // unimplemented
    }
    
    override func hitWall(_ hitDirection: RobotWallHitDirection, hitAngle angle: CGFloat) {
        cancelActiveAction()
        
        // save old state
        let previousState = currentRobotState
        currentRobotState = .turnaround
        
        // always turn directly away from wall
        if angle >= 0 {
            turnLeft(Int(abs(angle)))
        } else {
            turnRight(Int(abs(angle)))
        }
        
        // leave wall
        moveAhead(20)
        
        // turn gun around
        turnGunLeft(180)
        
        // reset to old state
        currentRobotState = previousState
    }
    
    override func bulletHitEnemy(at position: CGPoint) {
        shoot()
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
    
}
