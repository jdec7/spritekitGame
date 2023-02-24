//
//  GameScene.swift
//  spritekitGame
//
//  Created by  on 12/20/22.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var score: Int = 0
    
    //Nodes
    var tankBody = SKSpriteNode()
    var tankGun = SKSpriteNode()
    
    //var bullets : [SKSpriteNode] = []
    var moveStickKnob = SKSpriteNode()
    var moveStickBound = SKSpriteNode()
    var aimStickKnob = SKSpriteNode()
    var aimStickBound = SKSpriteNode()
    var chargeIndicator = SKSpriteNode()
    
    //Numbers
    var bulletSpeedModifier : CGFloat = 3000.0
    var movementAngle : CGFloat = 0.0
    var movementSpeedModifier : CGFloat = 2.0
    var tankAngularDamping : CGFloat = 100.0
    var tankLinearDamping : CGFloat = 0.9
    var tankFriction : CGFloat = 100.0
    var tankRestitution : CGFloat = 1.0
    var moveRange : CGFloat = 600.0
    var perimeterRespect : CGFloat = 300.0
    var enemySpeedModifier : CGFloat = 200.0
    var bulletLifetime: CGFloat = 4.0
    
    //Booleans
    var charged : Bool = false
    
    override func didMove(to view: SKView) {
        
        if(tankGun.position != tankBody.position)
        {
            tankGun.position = tankBody.position
        }
         
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = border
        resetWorld()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
    }
    
    
// functions for registering and responding to touches
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            for touch in touches {
                let location =  touch.location(in: self)
            
            //Movement joystick Knob
                //brings knob to position of a touch within the bound
                if moveStickBound.frame.contains(location) {
                    moveStickKnob.position = location
                    
                    tankBody.physicsBody?.linearDamping = 0.0
                    
                    //MARK: Aims the tank to face a given direction
                    movementAngle = getAngle(a: moveStickBound.position, b: location)
                    tankBody.run(SKAction.rotate(toAngle: movementAngle - Double.pi / 2, duration: 0.1, shortestUnitArc: true))
                   
                    //MARK: Updates tank velocity
                    tankBody.physicsBody?.velocity = CGVector(dx: movementSpeedModifier * (moveStickKnob.position.x - moveStickBound.position.x), dy: movementSpeedModifier * (moveStickKnob.position.y - moveStickBound.position.y))

                }
                
                //returns the knob to center if your finger leaves the bound
                if moveStickKnob.frame.contains(touch.previousLocation(in: self)) && !moveStickKnob.frame.contains(location) {
                    moveStickKnob.position = moveStickBound.position
                    tankBody.physicsBody?.linearDamping = tankLinearDamping
                }
            
                
            //Shooting joystick Knob
                //brings knob to position of a touch within the bound
                if aimStickBound.frame.contains(location) {
                    aimStickKnob.position = location
                    
                    if !charged {
                    //MARK: CHARGE INDICATOR ACTIONS
                        let chargeUp = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
                        let CIFadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.7)
                        let CIFadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.7)
                    let breathe = SKAction.sequence([CIFadeOut, CIFadeIn])
                    let breatheForever = SKAction.repeatForever(breathe)
                    let chargeThenBlink = SKAction.sequence([chargeUp, breatheForever])
                        chargeIndicator.run(chargeThenBlink)
                        charged = true

                   
                }
                    //MARK: Aims the tank gun to face a given direction
                    tankGun.run(SKAction.rotate(toAngle: getAngle(a: aimStickBound.position, b: location) - tankBody.zRotation + Double.pi/2, duration: 0.1, shortestUnitArc: true))
                
                    
                    
                }
                else {
                    tankGun.run(SKAction.rotate(toAngle: Double.pi, duration: 0.1, shortestUnitArc: true))
                }
                
                //returns the knob to center if your finger leaves the bound
                if aimStickKnob.frame.contains(touch.previousLocation(in: self)) && !aimStickKnob.frame.contains(location) {
                    aimStickKnob.position = aimStickBound.position
                    resetChargeIndicator()
                    
                }
                
            }
            
            
            
            
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

            for touch in touches {
            
            //Movement joystick Knob
                
                //returns the knob to center if your finger leaves the bound
                if moveStickKnob.frame.contains(touch.previousLocation(in: self)) {
                    moveStickKnob.position = moveStickBound.position
                    tankBody.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
                    tankBody.physicsBody?.linearDamping = tankLinearDamping
                }
            
                
            //Shooting joystick Knob
                
                //returns the knob to center if your finger leaves the bound
                if aimStickKnob.frame.contains(touch.previousLocation(in: self)) {
                    
                    //MAKES A BULLET
                    if charged {
                        makeBullet(origin: tankBody.position, angle: getAngle(a: aimStickBound.position, b: aimStickKnob.position))
                    }
                    resetChargeIndicator()

                    
                    aimStickKnob.position = aimStickBound.position
                }
                
            }
        

        }
    
    func didBegin(_ contact: SKPhysicsContact) {

        if contact.bodyA.categoryBitMask == 2 && contact.bodyB.categoryBitMask == 2
        {
            makeExplosion(position: contact.contactPoint, type: "explodeSmall")
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
        }
        
        if contact.bodyA.categoryBitMask == 2 && contact.bodyB.categoryBitMask == 4
        {
            makeExplosion(position: contact.contactPoint, type: "explodeLarge")
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
        }
        
        if contact.bodyA.categoryBitMask == 4 && contact.bodyB.categoryBitMask == 2
        {
            makeExplosion(position: contact.contactPoint, type: "explodeLarge")
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
        }
        
        if contact.bodyA.categoryBitMask == 2 && contact.bodyB.categoryBitMask == 1
        {
            makeExplosion(position: contact.contactPoint, type: "explodeLarge")
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            resetWorld()
        }
        
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 2
        {
            makeExplosion(position: contact.contactPoint, type: "explodeLarge")
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            resetWorld()
        }

        
    }
    
    
    //Function to make the bullets
    func makeBullet(origin: CGPoint, angle: CGFloat) {

        let bullet = SKSpriteNode(texture: SKTexture(imageNamed: "bulletGreen2_outline"), size: CGSize(width: 30, height: 50))
        bullet.position = CGPoint(x: origin.x + cos(angle) * 200, y: origin.y + sin(angle) * 200)
        bullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 50))
        bullet.physicsBody?.restitution = 1
        bullet.physicsBody?.linearDamping = 0.97
        bullet.physicsBody?.friction = 0
        bullet.physicsBody?.angularDamping = 0.9
        //set velocity of bullet
        bullet.physicsBody?.velocity = CGVector(dx: (bulletSpeedModifier * (cos(angle))), dy: (bulletSpeedModifier * (sin(angle))))
        //create bullet
        addChild(bullet)
        bullet.zRotation = angle - Double.pi / 2
        //collisions
        bullet.physicsBody?.categoryBitMask = 2
        bullet.physicsBody?.contactTestBitMask = 1|2|4|8

        //Code to cause the bullet to get destroyed after a certain amount of time
        let FadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.2)
        let FadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        let breathe = SKAction.sequence([FadeOut, FadeIn])
        let breatheLoop = SKAction.repeat(breathe, count: 5)
        let lifetimeWait = SKAction.wait(forDuration: bulletLifetime)
       // let blinkWait = SKAction.wait(forDuration: bulletBlinkTime)
        let remove = SKAction.run {
            self.makeExplosion(position: bullet.position, type: "explodeSmall")
            bullet.removeFromParent()
        }
        bullet.run(SKAction.sequence([lifetimeWait, breatheLoop, remove]))
    }
    
    //Function to place in enemies
    func makeEnemies() {
        let wait = SKAction.wait(forDuration: 1.0)
        let createEnemy = SKAction.run(makeEnemy)
        let sequence = SKAction.sequence([wait, createEnemy])
        let rpt = SKAction.repeatForever(sequence)
        run(rpt)
    }
    
    //Function to make enemies
    func makeEnemy() {
        let enemy = SKSpriteNode()
        let enemyBody = SKSpriteNode(texture: SKTexture(imageNamed: "tankBody_red_outline"), size: CGSize(width: 190, height: 200))
        let enemyGun = SKSpriteNode(texture: SKTexture(imageNamed: "tankDark_barrel2_outline"), size: CGSize(width: 60, height: 190))
        enemyGun.anchorPoint = CGPoint(x: 0.5, y: 0.9)
        enemyGun.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 200, height: 200))
        enemy.physicsBody?.angularDamping = tankAngularDamping
        enemy.physicsBody?.linearDamping = tankLinearDamping
        enemy.physicsBody?.friction = tankFriction
        enemy.physicsBody?.restitution = tankRestitution
        enemy.addChild(enemyBody)
        enemy.addChild(enemyGun)
        enemy.position = CGPoint(x: CGFloat.random(in: 100...frame.width-100), y: CGFloat.random(in: 100...frame.height-100))
        
        //Collisions
        enemy.physicsBody?.categoryBitMask = 4
        enemy.physicsBody?.contactTestBitMask = 1|2|4|8
        
        //set alpha to zero before adding
        enemy.alpha = 0
        addChild(enemy)
        enemy.zRotation = CGFloat.random(in: 0...(2 * .pi))
        let FadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        enemy.run(FadeIn)
        //wait between actions
        let wait = SKAction.wait(forDuration: 1.0, withRange: 1.0)
        //aim at the player
        let aimAtPlayer = SKAction.run { [self] in
            enemyGun.run(SKAction.rotate(toAngle: self.getAngle(a: enemy.position, b: tankBody.position) - enemy.zRotation + Double.pi / 2, duration: 0.5, shortestUnitArc: true))
        }
        //shoot
        let shoot = SKAction.run { [self] in
            makeBullet(origin: enemy.position, angle: enemyGun.zRotation + enemy.zRotation - Double.pi / 2)
        }
        //move to random location within x pixels (sequence)
        let move = SKAction.run { [self] in
            let randomPoint = CGPoint(
                x: CGFloat.random(in: ((enemy.position.x - moveRange) > perimeterRespect ? (enemy.position.x - moveRange) : perimeterRespect)...(enemy.position.x + moveRange > (frame.width - perimeterRespect) ? (frame.width - perimeterRespect) : (enemy.position.x + moveRange) ) ),
                y: CGFloat.random(in: (enemy.position.y - moveRange > perimeterRespect ? (enemy.position.y - moveRange) : perimeterRespect)...(enemy.position.y + moveRange > (frame.height - moveRange) ?  (frame.height - perimeterRespect) : (enemy.position.y + moveRange) ) ) )
            enemyBody.run(SKAction.rotate(toAngle: getAngle(a: enemy.position, b: randomPoint) + Double.pi / 2, duration: 0.5, shortestUnitArc: true))
            enemyGun.run(SKAction.rotate(toAngle: getAngle(a: enemy.position, b: randomPoint) + Double.pi / 2, duration: 0.5, shortestUnitArc: true))
            enemy.run(SKAction.wait(forDuration: 3.0))
            enemy.run(SKAction.move(to: randomPoint, duration: getDist(a: enemy.position, b: randomPoint) / enemySpeedModifier))
        }
        
        let enemyActions = SKAction.sequence([wait, aimAtPlayer, wait, shoot, wait, move])
        
        enemy.run(SKAction.repeatForever(enemyActions))
    }
   
    
    //Player's Tank
    func makePlayerTank() {

        //make tank body
        tankBody = SKSpriteNode(texture: SKTexture(imageNamed: "tankBody_green_outline"), size: CGSize(width: 190, height: 200))
        tankBody.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        tankBody.zPosition = 1
        tankBody.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 120, height: 200))
        tankBody.physicsBody?.angularDamping = tankAngularDamping
        tankBody.physicsBody?.linearDamping = tankLinearDamping
        tankBody.physicsBody?.friction = tankFriction
        tankBody.physicsBody?.restitution = tankRestitution
        
        tankGun = SKSpriteNode(texture: SKTexture(imageNamed: "tankGreen_barrel2_outline"), size: CGSize(width: 60, height: 190))
        //tankGun.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        tankGun.anchorPoint = CGPoint(x: 0.5, y: 0.9)
        tankGun.zPosition = 2
    
        
        tankBody.addChild(tankGun)
        addChild(tankBody)
        
        //collisions
        tankBody.physicsBody?.categoryBitMask = 1
        tankBody.physicsBody?.contactTestBitMask = 1|2|4|8
        
    }

    
    func makeJoySticks() {
        //Place in the move joystick
        moveStickKnob = SKSpriteNode(texture: SKTexture(imageNamed: "circle"), size: CGSize(width: frame.width/10, height: frame.width/10))
        moveStickKnob.alpha = 0.4
        moveStickKnob.position = CGPoint(x: frame.width / 8, y: frame.height / 5)
        moveStickKnob.zPosition = 4
        moveStickBound = SKSpriteNode(texture: SKTexture(imageNamed: "circle"), size: CGSize(width: frame.width/5, height: frame.width/5 ))
        moveStickBound.alpha = 0.2
        moveStickBound.position = CGPoint(x: frame.width / 8, y: frame.height / 5)
        moveStickBound.zPosition = 4
        addChild(moveStickBound)
        addChild(moveStickKnob)
        
        //Place in the shooting joystick
        aimStickKnob = SKSpriteNode(texture: SKTexture(imageNamed: "circle"), size: CGSize(width: frame.width/10, height: frame.width/10))
        aimStickKnob.alpha = 0.4
        aimStickKnob.position = CGPoint(x: 7 * frame.width / 8, y: frame.height / 5)
        aimStickKnob.zPosition = 4
        aimStickBound = SKSpriteNode(texture: SKTexture(imageNamed: "circle"), size: CGSize(width: frame.width/5, height: frame.width/5))
        aimStickBound.alpha = 0.2
        aimStickBound.position = CGPoint(x: 7 * frame.width / 8, y: frame.height / 5)
        aimStickBound.zPosition = 4
        chargeIndicator = SKSpriteNode(texture: SKTexture(imageNamed: "redCircle"), size: CGSize(width: moveStickBound.size.width * 1.235, height: moveStickBound.size.width * 1.235))
        chargeIndicator.position = aimStickBound.position
        chargeIndicator.alpha = 0.0
        addChild(chargeIndicator)
        addChild(aimStickBound)
        addChild(aimStickKnob)
        
    }
    
    
    
    func makeExplosion(position: CGPoint, type: String) {
    
        let fireEffect : SKEmitterNode = SKEmitterNode(fileNamed: type)!
        fireEffect.position = position
        fireEffect.particleColor = UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1)
        
        addChild(fireEffect)
        let shortWait = SKAction.wait(forDuration: 0.05)
        let stopBirth = SKAction.run {
            fireEffect.particleBirthRate = 0
        }
        let longWait = SKAction.wait(forDuration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.run {
            fireEffect.removeFromParent()
        }
        fireEffect.run(SKAction.sequence([shortWait, stopBirth, longWait, fade, longWait, remove]))
    }
    
    //calculate angle of line between two points, origin (a) and destination (b)
    func getAngle(a: CGPoint, b: CGPoint) -> Double{
        return atan2(b.y - a.y , b.x - a.x)
    }
    
    func resetChargeIndicator() {
        chargeIndicator.removeAllActions()
        chargeIndicator.alpha = 0.0
        charged = false
    }
    
    func getXDist(a: CGPoint, b: CGPoint) -> (CGFloat) {
        return(a.x - b.x)
    }
    
    func getYDist(a: CGPoint, b: CGPoint) -> (CGFloat) {
        return(a.y - b.y)
    }
    
    func getDist(a: CGPoint, b: CGPoint) -> (CGFloat) {
        return(sqrt(pow(getXDist(a: a, b: b),2) + pow(getYDist(a: a, b: b),2)))
    }
    
    func resetWorld() {
        
        let reset = SKAction.run {
            self.removeAllChildren()
            self.removeAllActions()
            self.makePlayerTank()
            self.makeJoySticks()
            self.makeEnemies()
        }
        
        run(SKAction.sequence([SKAction.wait(forDuration: 3.0), reset]))
           
        
    }
    
}


