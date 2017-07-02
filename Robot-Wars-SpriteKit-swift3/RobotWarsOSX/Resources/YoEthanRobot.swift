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
        case firstMovement, startScanShooting, hunterKiller, searchAndDestroy, gotHit, finiteScan
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
    var flagThree = false
    var flagFour = false
    
    /* enum declarations */
    var whichCorner: startCorner = .bottomLeft
    var currentRobotState: RobotState = .firstMovement
    var currentMoveState: moveState = .forward
    
    var lastKnownPosition = CGPoint(x: 0, y: 0)
    var lastKnownPositionTimestamp = CGFloat(0.0)
    let gunToleranceAngle = CGFloat(2.0)
    let firingTimeout = CGFloat(5.0)
    var actionIndex = 0
    var secondConstant = 0
    
    var enemyHealth = 20
    
    var gunAngle = 0
    
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
            case . finiteScan:
                tightenedScan()
                print("Tightened Scan")
            case .gotHit:
                flag = false
                flagTwo = false
                flagThree = false
                currentRobotState = .startScanShooting

            }
        }
    }
    
    func performNextFiringAction() {
        if currentTimestamp() - lastKnownPositionTimestamp > firingTimeout {
            print("if statement is flagging")
            flagTwo = false
            flagThree = false
            secondConstant = 0
            currentRobotState = .finiteScan
        } else {
            print ("blast them")
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
        if currentRobotState != .hunterKiller {
            cancelActiveAction()
        }
        
        flagTwo = true
        flagThree = true
        lastKnownPosition = position
        lastKnownPositionTimestamp = currentTimestamp()
        currentRobotState = .hunterKiller
    }
    
    override func gotHit() {
        if currentRobotState == .hunterKiller && hitPoints() > enemyHealth {
            return
        }
        
        if currentRobotState == .gotHit {
            return
        } else {
            currentRobotState = .gotHit
        }
        flagTwo = false
        flagThree = false
     //   flagFour = false
        
        resetToTurret()
        
    }
    
    
    func resetToTurret(){
        let bodySize = robotBodySize()
        let arenaSize = arenaDimensions()
        let toTheEdge = Int(arenaSize.width/2 - bodySize.width)
        let toTheTop = Int(arenaSize.height - bodySize.width)
        
//        if flagFour == true {
//            return
//        }
            switch whichCorner {
                
            case .bottomLeft:
                moveAhead(toTheEdge)
                turnLeft(90)
                moveAhead(toTheTop)
                turnLeft(90)
                moveAhead(toTheEdge)
                turnToCenter()
                whichCorner = .topRight
                flagFour = true
                
                
            case .topLeft:
                moveAhead(toTheEdge)
                turnRight(90)
                moveAhead(toTheTop)
                turnRight(90)
                moveAhead(toTheEdge)
                turnToCenter()
                whichCorner = .bottomRight
                flagFour = true

                
            case .bottomRight:
                moveAhead(toTheEdge)
                turnRight(90)
                moveAhead(toTheTop)
                turnRight(90)
                moveAhead(toTheEdge)
                turnToCenter()
                whichCorner = .topLeft
                flagFour = true
                
                
            case .topRight:
                moveAhead(toTheEdge)
                turnLeft(90)
                moveAhead(toTheTop)
                turnLeft(90)
                moveAhead(toTheEdge)
                turnToCenter()
                whichCorner = .bottomLeft
                flagFour = true

                
            }
   
        
    }
    
    
    override func bulletHitEnemy(at position: CGPoint) {
        enemyHealth -= 1
        
        if currentRobotState == .hunterKiller {
            lastKnownPosition = position
            lastKnownPositionTimestamp = currentTimestamp()
            currentRobotState = .hunterKiller
        }
        
        if currentRobotState == .finiteScan {
            flagThree = true
            cancelActiveAction()
            print("Hit an enemy in finiteScane")
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
        movingAcross()
        aimAtCenter()
        //turnToCenter()
        
        currentRobotState = .startScanShooting
    }
    
    
    
    func movingAcross() {
        let arenaSize = arenaDimensions()
        let bodyLength = robotBodySize().width
        let initialMovement = Int(arenaSize.width/2 - bodyLength)
        
        switch whichCorner {
        case .bottomLeft:
            turnRight(90)
            moveAhead(initialMovement)
        case .bottomRight:
            turnLeft(90)
            moveAhead(initialMovement)
        case .topLeft:
            turnLeft(90)
            moveAhead(initialMovement)
        case .topRight:
            turnRight(90)
            moveAhead(initialMovement)
        }
    }
    
    
    func tightenedScan() {
        var angleToTurn = 0
        let angleIncrement = 10
        var constant = 3
        //  var secondConstant = 0
        for _ in 1 ... constant {
            if secondConstant <= constant {
                if flagThree == false {
                    angleToTurn += angleIncrement
                    turnGunRight(angleToTurn)
                    shoot()
                    turnGunLeft(angleToTurn * 2)
                    shoot()
                    turnGunRight(angleToTurn)
                    shoot()
                    secondConstant += 1
                    print(secondConstant)
                } else { break }
            } else {
                print("This is actually flagging)")
                turnToCenter()
                flag = false
                currentRobotState = .startScanShooting
            }
            
        }
    }
    
    
    
    
    func startScanShooting() {
        let arenaSize = arenaDimensions()
        
        let topLeftAngle = angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: 0, y: arenaSize.height))
        let topRightAngle = angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: arenaSize.width, y: arenaSize.height))
        let bottomLeftAngle = angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x:0, y: 0))
        let bottomRightAngle = angleBetweenGunHeadingDirectionAndWorldPosition(CGPoint(x: arenaSize.width, y: 0))
        
        let numberOfShots = 24
        gunAngle = 180/numberOfShots
        print("Printing Top Left")
        print(topLeftAngle)
        
        print("Printing bottom Left")
        print(bottomRightAngle)

        
        
        switch whichCorner{
        case .bottomLeft:
            if flag == false{
                turnGunRight(Int(bottomRightAngle - 10))
                shoot()
                flag = true
            }
            if flag == true {
                for _ in 1 ... numberOfShots {
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
                for _ in 1 ... numberOfShots {
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
                for _ in 1 ... numberOfShots {
                    if flagTwo == false {
                        turnGunRight(gunAngle)
                        shoot()
                    } else { break }
                }
                flag = false
            }
        case .topRight:
            if flag == false {
                turnGunRight(Int(350 - (topLeftAngle * -1 )))
                shoot()
                flag = true
            }
            if flag == true {
                for _ in 1 ... numberOfShots {
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
    
    func aimAtCenter() {
        switch whichCorner{
        case .bottomLeft:
            turnGunLeft(90)
        case .topLeft:
            turnGunRight(90)
        case .bottomRight:
            turnGunRight(90)
        case .topRight:
            turnGunLeft(90)
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











