import VPlay 2.0
import QtQuick 2.0
import "scenes"

GameWindow {
  id: gameWindow
  // start size of the window
  // usually set to resolution of main target device, this resolution is for iPhone 4/4S
  screenWidth: 640
  screenHeight: 960

  // the entity manager allows dynamic creation of entities within the game scene (e.g. bullets and coins)
  EntityManager {
      id: entityManager
      entityContainer: gameScene
  }

  // menu scene
  MenuScene {
    id: menuScene
    // listen to the button signals of the scene and change the state according to it
    onCreditsPressed: gameWindow.state = "credits"
    onQuickGamePressed: gameWindow.state = "game"


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
