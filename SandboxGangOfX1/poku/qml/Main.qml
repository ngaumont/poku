import VPlay 2.0
import QtQuick 2.0
import "scenes"
import "common"
import Qt.labs.settings 1.0




GameWindow {
  id: gameWindow
  // start size of the window
  // usually set to resolution of main target device, this resolution is for iPhone 4/4S
  screenWidth: 640
  screenHeight: 960
  licenseKey: Constants.licenseKey

  // the entity manager allows dynamic creation of entities within the game scene (e.g. bullets and coins)
  EntityManager {
      id: entityManager
      entityContainer: gameScene
  }

  // menu scene
  MenuScene {
    id: menuScene
    // listen to the button signals of the scene and change the state according to it
    onCreditsPressed: {
        gameWindow.state = "credits"
    }
    onQuickGamePressed: {
        console.log("Create local game")
//        gameScene.deck.createDeck()
//        gameScene.playerHands.bottomHand.startHand()
//        multiplayer.createSinglePlayerGame()
        gameScene.gameLogic.startNewGame()
        gameWindow.state = "game"
    }


    // the title scene is our start scene, so if back is pressed there (on android) we ask the user if he wants to quit the application
    onBackButtonPressed: {
       nativeUtils.displayMessageBox("Really quit the game?", "", 2)
    }
    // listen to the return value of the MessageBox
    Connections {
       target: nativeUtils
       onMessageBoxFinished: {
       // only quit, if the activeScene is titleScene - the messageBox might also get opened from other scenes in your code
           if(accepted && gameWindow.activeScene === menuScene)
              Qt.quit()
        }
     }

  }


  VPlayGameNetwork {
    id: gameNetwork
    // on mobile, set this to false as you would otherwise simulate a clean app start with no logged in user every time
    // only set it to true if you want to simulate different users
    clearAllUserDataAtStartup: system.desktopPlatform && enableMultiUserSimulation // this can be enabled during development to simulate a first-time app start
    clearOfflineSendingQueueAtStartup: true // clear any stored requests in the offline queue at app start, to avoid starting errors
    gameId: Constants.gameId
    secret: Constants.gameSecret
    user.deviceId: generateDeviceId()

    property int counterAppInstances: 0

    // set this property to true if you want to switch between multiplayer.playerCount players on Desktop
    // this simplifies multiplayer testing, because you get a new user at every app start and can test multiplayer functionality on the same PC
    property bool enableMultiUserSimulation: true

    function generateDeviceId() {
      // on mobile devices, no 2 app instances can be started at the same time, thus return the udid there
      if(system.isPlatform(System.IOS) || system.isPlatform(System.Android) || system.isPlatform(System.WindowsPhone)) {
        console.debug("xxx-setting deviceId to", system.UDID)
        return system.UDID
      }
      // this means the app was started on the same PC more than once, for testing a multiplayer game
      // in this case, append the counterAppInstances value to the deviceID to have 2 separate players
      if(counterAppInstances > 1 && enableMultiUserSimulation) {
        return system.UDID + "_" + (counterAppInstances) % multiplayer.playerCount
      } else {
        return system.UDID
      }
    }
  }

  VPlayMultiplayer {
    id: multiplayer

    playerCount: 4
    startGameWhenReady: true
//    gameNetworkItem: gameNetwork
//    multiplayerView: matchmakingScene && matchmakingScene.mpView
    maxJoinTries: 5
    fewRoomsThreshold: 3
    joinRankingIncrease: 200
    enableLateJoin: false // allow joining a running match after it was started (if the match has non-human (AI) players to fill the game
    appVersion: "1.5.0" // 1.5.0 (changed on 8.8.2016, with versionCode 17) adds new messages that correctly trigger a new game start (also a restart). changing it is important, to not interfere with players of the published OneCard games that did not update yet and to prevent players of the old and new version can play together
    latencySimulationTime: system.desktopPlatform && !system.publishBuild ? 2000 : 0 // allows to simulate latency values on Desktop. for published games, always set this to 0!

//    appKey: Constants.appKey
//    pushKey: Constants.pushKey


    onGameStarted: {
      console.debug("yyy-gameStarted")
      // increase gamesPlayed counter for every game start and decrease tokens
      gameWindow.state = "game"
    }
  }


  // credits scene
  CreditsScene {
    id: creditsScene
     onBackButtonPressed: gameWindow.state = "menu"
  }

  // game scene to play a poku game
  GameScene {
    id: gameScene
     onBackButtonPressed: gameWindow.state = "menu"
  }

  // default state is menu -> default scene is menuScene
    state: "menu"

    // state machine, takes care reversing the PropertyChanges when changing the state like changing the opacity back to 0
    states: [
      State {
        name: "menu"
        PropertyChanges {target: menuScene; opacity: 1}
        PropertyChanges {target: gameWindow; activeScene: menuScene}
      },

      State {
        name: "credits"
        PropertyChanges {target: creditsScene; opacity: 1}
        PropertyChanges {target: gameWindow; activeScene: creditsScene}
      },
      State {
        name: "game"
        PropertyChanges {target: gameScene; opacity: 1}
        PropertyChanges {target: gameWindow; activeScene: gameScene}
      }
    ]



}
