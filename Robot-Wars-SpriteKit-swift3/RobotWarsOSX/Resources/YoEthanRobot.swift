//
//  YoEthanRobot.swift
//  RobotWar
//
//  Created by Dion Larson on 7/2/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation

class YoEthanRobot: Robot {
    
    /* ----------- Defining enums for later use --------- */
    enum RobotState {                    // enum for keeping track of RobotState
        case firstMovement, startScanShooting, hunterKiller, searchAndDestroy, turnAround
    }
    
    enum startCorner {
        case bottomLeft, bottomRight, topLeft, topRight
    }
    
    
    enum moveState {
        case left, right, forward, forwardTwo
        
    }
    
    
    /* Variable definitions */
    var flag = false
    var flagTwo = false
    
    /* enum declarations */
    var whichCorner: startCorner = .bottomLeft
    var currentRobotState: RobotState = .firstMovement
    var currentMoveState: moveState = .forward
    
    var lastKnownPosition = CGPoint(x: 0, y: 0)
    var lastKnownPositionTimestamp = CGFloat(0.0)
    let gunToleranceAngle = CGFloat(2.0)
    let firingTimeout = CGFloat(5.0)
    var actionIndex = 0
    
    var gunAngle = 0
    var totalDegreesInitial = 0
    
    
    
    override func run() {
        while true {
            switch currentRobotState {
            case .firstMovement:
                firstMovement()
            case .startScanShooting:
                startScanShooting()
            case .hunterKiller:
                performNextFiringAction()
                print("Exterminate!")
            case .searchAndDestroy:
                performNextSearchingAction()
            case .turnAround:
                break
            }
        }
    }
    
    func performNextDefaultAction() {
        // uses actionIndex with switch in case you want to expand and add in more actions
        // to your initial state -- first thing robot does before scanning another robot
        switch actionIndex % 1 {          // should be % of number of possible actions
        case 0:
            moveAhead(25)
            currentRobotState = .searchAndDestroy
        default:
            break
        }
        actionIndex += 1
    }
    
    func performNextFiringAction() {
        if currentTimestamp() - lastKnownPositionTimestamp > firingTimeout {
            turnToCenter()
            print("if statement is flagging")
            flagTwo = false
            currentRobotState = .startScanShooting
        } else {
            let angle = Int(angleBetweenGunHeadingDirectionAndWorldPosition(lastKnownPosition))
            if angle >= 0 {
                turnGunRight(abs(angle))
            } else {
                turnGunLeft(abs(angle))
            }
            shoot()
            
        }
    }
    
    
    
    override func scannedRobot(_ robot: Robot!, atPosition position: CGPoint) {
        //        if currentRobotState != .lockOn {
        //            cancelActiveAction()
        //        }
        //
        //        lastKnownPosition = position
        //        lastKnownPositionTimestamp = currentTimestamp()
        //        currentRobotState = .lockOn
    }
    
    override func gotHit() {
        if currentRobotState == .hunterKiller {
            return
        }
        moveAhead(120)
        
        currentRobotState = .searchAndDestroy
    }
    
    override func hitWall(_ hitDirection: RobotWallHitDirection, hitAngle angle: CGFloat) {
        cancelActiveAction()
        
        // save old state
        let previousState = currentRobotState
        currentRobotState = .turnAround
        
        // always turn directly away from wall
        if angle >= 0 {
            turnLeft(Int(abs(angle)))
        } else {
            turnRight(Int(abs(angle)))
        }
        
        // leave wall
        moveAhead(20)
        
        // reset to old state
        currentRobotState = previousState
    }
    
    
    override func bulletHitEnemy(at position: CGPoint) {
        if currentRobotState == .hunterKiller {
            lastKnownPosition = position
            lastKnownPositionTimestamp = currentTimestamp()
            currentRobotState = .hunterKiller
        }
        if currentRobotState == .startScanShooting {
            flagTwo = true
            cancelActiveAction()
            lastKnownPosition = position
            lastKnownPositionTimestamp = currentTimestamp()
            currentRobotState = .hunterKiller
        }
        
        
        
        
    }
    
    func turnToEnemyPosition(_ position: CGPoint) {
        //        cancelActiveAction()
        //
        //        // calculate angle between turret and enemey
        //        let angleBetweenTurretAndEnemy = angleBetweenGunHeadingDirectionAndWorldPosition(position)
        //
        //        // turn if necessary
        //        if angleBetweenTurretAndEnemy > gunToleranceAngle {
        //            turnGunRight(Int(abs(angleBetweenTurretAndEnemy)))
        //        } else if angleBetweenTurretAndEnemy < -gunToleranceAngle {
        //            turnGunLeft(Int(abs(angleBetweenTurretAndEnemy)))
        //        }
    }
    
    /* ---------- Original Functions ---------- */
    func firstMovement() {
        let arenaSize = arenaDimensions()
        let bodyLength = robotBodySize().width
        
        // find and turn towards closest corner
        var currentPosition = position()
        if currentPosition.y < arenaSize.height / 2 {
            if currentPosition.x < arenaSize.width/2 {
                // bottom left
                turnLeft(90)
                whichCorner = .bottomLeft
            } else {
                // bottom right
                turnRight(90)
                whichCorner = .bottomRight
            }
        } else {
            if currentPosition.x < arenaSize.width/2 {
                // top left
                turnRight(90)
                whichCorner = .topLeft
            } else {
                // top right
                turnLeft(90)
                whichCorner = .topRight
            }
        }
        
        // back into closest corner
        currentPosition = position()
        if currentPosition.y < arenaSize.height/2 {
            moveBack(Int(currentPosition.y - bodyLength))
        } else {
            moveBack(Int(arenaSize.height - (currentPosition.y + bodyLength)))
        }
        //        turnToOtherSide()
        movingAcross()
        
        currentRobotState = .startScanShooting
    }
    
    func startScanShooting() {
        let arenaSize = arenaDimensions()
        var topLeftAngle = angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: 0, y: arenaSize.height))
        var topRightAngle = angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: arenaSize.width, y: arenaSize.height))
        var bottomLeftAngle = angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x:0, y: 0))
        var bottomRightAngle = angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: arenaSize.width, y: 0))
        
        let numberOfShots = 24
        gunAngle = 180/numberOfShots
        
        totalDegreesInitial += 10
        if totalDegreesInitial > 180 {
            totalDegreesInitial = -190
        }
        print("expected height")
        print(topRightAngle)
        
        switch whichCorner{
        case .bottomLeft:
            if flag == false{
                turnGunRight(Int(bottomRightAngle - 10))
                shoot()
                flag = true
            }
            if flag == true {
                for gunGun in 1 ... numberOfShots {
                    if flagTwo == false {
                        turnGunLeft(gunAngle)
                        shoot()
                    } else { break }
                }
                flag = false
            }
        case .bottomRight:
            if flag == false{
                turnGunLeft(Int(350 - bottomLeftAngle))
                shoot()
                flag = true
            }
            if flag == true {
                for gunGun in 1 ... numberOfShots {
                    if flagTwo == false {
                        turnGunRight(gunAngle)
                        shoot()
                    } else { break }
                }
                flag = false
            }
        case .topLeft:
            if flag == false{
                turnGunLeft(Int((topRightAngle * -1) - 10))
                shoot()
                flag = true
            }
            if flag == true{
                for gunGun in 1 ... numberOfShots {
                    if flagTwo == false {
                        turnGunRight(gunAngle)
                        shoot()
                    } else { break }
                }
                flag = false
            }
        case .topRight:
            if flag == false {
                turnGunRight(Int(350 - (topLeftAngle * -1)))
                shoot()
                flag = true
            }
            if flag == true {
                for gunGun in 1 ... numberOfShots {
                    if flagTwo == false {
                        turnGunLeft(gunAngle)
                        shoot()
                    } else { break }
                }
                flag = false
            }
        }
    }
    
    func performNextSearchingAction() {
        switch actionIndex % 4 {          // should be % of number of possible actions
        case 0:
            moveAhead(60)
        case 1:
            turnLeft(20)
        case 2:
            moveAhead(60)
        case 3:
            turnRight(40)
        default:
            break
        }
        actionIndex += 1
    }
    
    func turnToOtherSide() {
        
        switch whichCorner{
        case .bottomLeft:
            turnGunRight(55)
        case .topLeft:
            turnGunLeft(55)
        case .bottomRight:
            turnGunLeft(55)
        case .topRight:
            turnGunRight(55)
        }
        
    }
    
    func movingAcross() {
        let arenaSize = arenaDimensions()
        let bodySize = robotBodySize()
        let initialMovement = Int(arenaSize.width/2 - bodySize.width)
        
        switch whichCorner {
        case .bottomLeft:
            turnRight(90)
            moveAhead(initialMovement)
        // turnLeft(90)
        case .bottomRight:
            turnLeft(90)
            moveAhead(initialMovement)
        //  turnRight(90)
        case .topLeft:
            turnLeft(90)
            moveAhead(initialMovement)
        //  turnRight(90)
        case .topRight:
            turnRight(90)
            moveAhead(initialMovement)
            //  turnLeft(90)
            
        }
    }
    
    
    func turnToCenter() {
        let arenaSize = arenaDimensions()
        let angle = Int(angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: arenaSize.width/2, y: arenaSize.height/2)))
        if angle < 0 {
            turnGunLeft(abs(angle))
        } else {
            turnGunRight(angle)
        }
    }
}











