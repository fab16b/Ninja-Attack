/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit
func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

struct PhysicsCategory {
  static let none      : UInt32 = 0
  static let all       : UInt32 = UInt32.max
  static let enemy   : UInt32 = 0b1       // 1
  static let projectile: UInt32 = 0b10      // 2
}


class GameScene: SKScene {
  // 1
  let friendShip = SKSpriteNode(imageNamed: "friend2")
  var enemiesDestroyed = 0

    
  override func didMove(to view: SKView) {
    // 2
    backgroundColor = SKColor.black
    // 3
    friendShip.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    // 4
    addChild(friendShip)
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self

    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addEnemy),
        SKAction.wait(forDuration: 1.0)
        
        ])
    ))
    
    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addStar),
        SKAction.wait(forDuration: 2.0)
        
        ])
    ))
    
    let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
    backgroundMusic.autoplayLooped = true
    addChild(backgroundMusic)
    
  }

  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }

  func addEnemy() {
    
    // Create sprite
    let enemy = SKSpriteNode(imageNamed: "enemy")
    enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size) // 1
    enemy.physicsBody?.isDynamic = true // 2
    enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy // 3
    enemy.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
    enemy.physicsBody?.collisionBitMask = PhysicsCategory.none // 5

    
    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: enemy.size.height/2, max: size.height - enemy.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: actualY)
    
    // Add the monster to the scene
    addChild(enemy)
    
    // Determine speed of the monster
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    // Create the actions
    let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/2, y: actualY),
                                   duration: TimeInterval(actualDuration))
    
    
    let actionMoveDone = SKAction.removeFromParent()
    let loseAction = SKAction.run() { [weak self] in
      guard let `self` = self else { return }
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    enemy.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))

  }
  
  
  func addStar() {
    
    // Create sprite
    let stars = SKSpriteNode(imageNamed: "stars")

    
    // Determine where to spawn the star along the Y axis
    let starY = random(min: stars.size.height/2, max: size.height - stars.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    stars.position = CGPoint(x: size.width + stars.size.width/2, y: starY)
    
    // Add the monster to the scene
    addChild(stars)
    
    // Determine speed of the monster
    let starDuration = random(min: CGFloat(4.0), max: CGFloat(8.0))
    
    // Create the actions
    let starMove = SKAction.move(to: CGPoint(x: -stars.size.width/2, y: starY), duration: TimeInterval(starDuration))
    
       stars.run(SKAction.sequence([starMove]))

  }
  
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1 - Choose one of the touches to work with
    guard let touch = touches.first else {
      return
    }
    
    run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))

    let touchLocation = touch.location(in: self)
    
    // 2 - Set up initial location of projectile
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = friendShip.position
    
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
    projectile.physicsBody?.usesPreciseCollisionDetection = true
    
    // 3 - Determine offset of location to projectile
    let offset = touchLocation - projectile.position
    
    // 4 - Bail out if you are shooting down or backwards
    if offset.x < 0 { return }
    
    // 5 - OK to add now - you've double checked position
    addChild(projectile)
    
    // 6 - Get the direction of where to shoot
    let direction = offset.normalized()
    
    // 7 - Make it shoot far enough to be guaranteed off screen
    let shootAmount = direction * 1000
    
    // 8 - Add the shoot amount to the current position
    let realDest = shootAmount + projectile.position
    
    // 9 - Create the actions
    let actionMove = SKAction.move(to: realDest, duration: 1.0)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
  }
  
  func projectileDidCollideWithEnemy(projectile: SKSpriteNode, enemy: SKSpriteNode) {
    print("Hit")
    projectile.removeFromParent()
    enemy.removeFromParent()
  }

}

extension GameScene: SKPhysicsContactDelegate {
  
  func didBegin(_ contact: SKPhysicsContact) {
    // 1
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
   
    // 2
    if ((firstBody.categoryBitMask & PhysicsCategory.enemy != 0) &&
        (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
      if let enemy = firstBody.node as? SKSpriteNode,
        let projectile = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithEnemy(projectile: projectile, enemy: enemy)
        
        enemiesDestroyed += 1
        if enemiesDestroyed > 30 {
          let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
          let gameOverScene = GameOverScene(size: self.size, won: true)
          view?.presentScene(gameOverScene, transition: reveal)
        }

      }
    }
  }
}

