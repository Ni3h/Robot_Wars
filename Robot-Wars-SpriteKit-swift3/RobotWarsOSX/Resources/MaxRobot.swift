//
//  AdvancedRobotSwift.swift
//  RobotWar
//
//  Created by Dion Larson on 7/2/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation

class MaxRobot: Robot
{
    var moveValue = 50
    var moveToBullets = true
    
    enum RobotState
    {                    // enum for keeping track of RobotState
        case `default`, turnaround, firing, searching
    }
    
    var currentRobotState: RobotState = .default
    {
        didSet
        {
            actionIndex = 0
        }
    }
    var actionIndex = 0                 // index in sub-state machines, could use enums
    // but will make harder to quickly add new states
    
    var lastKnownPosition = CGPoint(x: 0, y: 0)
    var lastKnownPositionTimestamp = CGFloat(0.0)
    let firingTimeout = CGFloat(1.0)
    let gunToleranceAngle = CGFloat(2.0)
    var scatter = false

    func camper(position: CGPoint)
    {
        turnToEnemyPosition(position)
        shoot()
    }
    override func run()
    {
        while true
        {
            switch currentRobotState
            {
            case .default:
                performNextDefaultAction()
            case .searching:
                scatter = false
                performNextSearchingAction()
            case .firing:
                performNextFiringAction()
            case .turnaround:               // ignore Turnaround since handled in hitWall
                break
            }
        }
    }
    
    func performNextDefaultAction()
    {
        // uses actionIndex with switch in case you want to expand and add in more actions
        // to your initial state -- first thing robot does before scanning another robot
        switch actionIndex % 1
        {          // should be % of number of possible actions
        case 0:
            moveAhead(90)
            turnRight(90)
            turnGunLeft(90)
            currentRobotState = .searching
        default:
            break
        }
        actionIndex += 1
    }
    
    func performNextSearchingAction()
    {
        let angle = Int(angleBetweenGunHeadingDirectionAndWorldPosition(position()))
        moveToBullets = true
        
        switch actionIndex % 4
        {          // should be % of number of possible actions
        case 0:
            moveAhead(50)
            
        case 1:
            shoot()
        case 2:
            moveAhead(50)
            
        case 3:
            shoot()
        default:
            break
        }
        actionIndex += 1
    }
    
    func performNextFiringAction()
    {
        moveToBullets = false
        

        cancelActiveAction()
        if currentTimestamp() - lastKnownPositionTimestamp > firingTimeout
        {
            currentRobotState = .searching
        }
        
        
        shoot()
        
    }
    
    override func scannedRobot(_ robot: Robot!, atPosition position: CGPoint)
    {
        cancelActiveAction()
        scatter = true
        moveToBullets = false
        lastKnownPosition = position
        turnToEnemyPosition(position)
        currentRobotState = .firing
        
    }
    
    override func gotHit()
    {

        cancelActiveAction()
        moveAhead(50)
    }
    
    override func hitWall(_ hitDirection: RobotWallHitDirection, hitAngle angle: CGFloat)
    {
//        cancelActiveAction()
        
//         save old state
        if currentRobotState != .firing
        {
            let previousState = currentRobotState
            currentRobotState = .turnaround
            
    //         always turn directly away from wall
            if angle >= 0 {
                turnLeft(Int(abs(angle)))
            }
            else
            {
                turnRight(Int(abs(angle)))
            }
            
    //         leave wall
            moveAhead(30)
            
            // reset to old state
            currentRobotState = previousState
            turnGunRight(180)
            
    //        moveValue *= -1
    //        moveAhead(moveValue)
        }
        else
        {
            moveBack(200)
        }
        
    }
    
    override func bulletHitEnemy(at position: CGPoint)
    {
        lastKnownPosition = position
        if moveToBullets == true && currentTimestamp() - lastKnownPositionTimestamp > firingTimeout
        {
//            cancelActiveAction()
            if currentRobotState == .searching
            {
//                cancelActiveAction()
                turnToEnemyPositionAndShoot(position)
            }
            
    //        else if (currentRobotState != .firing)
    //        {
    //            turnToEnemyPosition(position)
    //            shoot()
    //        }
        }
//        else if currentRobotState == .searching
//        {
//            turnToEnemyPositionAndShoot(position)
//        }
        
        moveToBullets = false
        
    }
    
    func turnToEnemyPosition(_ position: CGPoint)
    {
//        cancelActiveAction()
        
        // calculate angle between turret and enemey
        let angleBetweenTurretAndEnemy = angleBetweenGunHeadingDirectionAndWorldPosition(position)
        
        // turn if necessary
        if angleBetweenTurretAndEnemy > gunToleranceAngle
        {
            turnGunRight(Int(abs(angleBetweenTurretAndEnemy)))
        }
        else if angleBetweenTurretAndEnemy < -gunToleranceAngle
        {
            turnGunLeft(Int(abs(angleBetweenTurretAndEnemy)))
        }
    }
    
    func turnToEnemyPositionAndShoot(_ position: CGPoint)
    {
        if currentRobotState != .firing
        {
            let angleBetweenTurretAndEnemy = angleBetweenGunHeadingDirectionAndWorldPosition(position)
            
            // turn if necessary
            if angleBetweenTurretAndEnemy > gunToleranceAngle
            {
                turnGunRight(Int(abs(angleBetweenTurretAndEnemy)))
                shoot()
                turnGunRight(15)
                shoot()
                turnGunLeft(15)
            
            }
            else if angleBetweenTurretAndEnemy < gunToleranceAngle
            {
                turnGunLeft(Int(abs(angleBetweenTurretAndEnemy)))
                shoot()
                turnGunLeft(20)
                shoot()
                turnGunRight(15)
    //
            }
        }
    }
}
