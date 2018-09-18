import VPlay 2.0
import QtQuick 2.0
import "scenes"

GameWindow {
  id: gameWindow


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
