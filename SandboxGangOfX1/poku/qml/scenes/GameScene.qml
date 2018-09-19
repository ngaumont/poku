import VPlay 2.0
import QtQuick 2.0
import "../common"
import "../game"

SceneBase {
  id:gameScene

  property alias deck: deck
//  property alias depot: depot
  property alias gameLogic: gameLogic

  MouseArea {
      anchors.fill: gameScene.gameWindowAnchorItem // check full game window
      property bool touch: false // true when user touches screen
      property int firstX: 0 // x position of swipe start point
      property int firstY: 0 // x position of swipe start point

      // recognize start of swipe on press
      onPressed: {
        if(touch == false){
            this.firstX = mouseX
            this.firstY = mouseY
        }
        touch = true
      }

      // recognize end of swipe on release
      onReleased: {
        if(touch == true)
            checkSwipe(15)
        touch = false
      }

      // also recognize swipe if mouse moved a long distance
      onPositionChanged: {
          if(touch)
            checkSwipe(60)
      }

      // move player based on swipe (left or right)
      function checkSwipe(minDistance) {
         var distanceX = mouseX - firstX
         var distanceY = mouseY - firstY
         if (Math.abs(distanceX) > Math.abs(distanceY)){
             if(Math.abs(distanceX) > minDistance) {
                if(distanceX > 0)
                   console.log("Swipe Right")
                else
                   console.log("Swipe Left")
                touch = false
             }
         }else {
             if(Math.abs(distanceY) > minDistance) {
                if(distanceY > 0)
                   console.log("Swipe Down")
                else
                   console.log("Swipe up")
                touch = false
             }
         }

      }
    }

  // background
  Rectangle {
    anchors.fill: parent.gameWindowAnchorItem
    color: "#dd94da"
  }
  MenuButton {
     text: "Back"
     anchors.left: gameScene.gameWindowAnchorItem.left
     anchors.leftMargin: 10
     anchors.bottom: gameScene.gameWindowAnchorItem.bottom
     anchors.bottomMargin: 10
     onClicked: backButtonPressed()
   }

  // contains all game logic functions
  GameLogic {
    id: gameLogic
  }

  // the deck on the right of the depot
  // Should not be visible as all card are drawn
  Deck {
    id: deck
  }


  // the playerTags for each playerHand
  Item {
    id: playerTags
    anchors.fill: gameWindowAnchorItem

    Text {
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 5
      anchors.right: parent.right
      anchors.rightMargin: 10
      text: "South"
      color: "black"
      font.pixelSize: 28
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      anchors.topMargin: 50
      text: "East"
      color: "black"
      font.pixelSize: 28
    }

    Text {
      anchors.top: parent.top
      anchors.topMargin: 10
      anchors.left: parent.left
      anchors.leftMargin: 10
      text: "North"
      color: "black"
      font.pixelSize: 28
    }

    Text {
      id: rightPlayerTag
      anchors.right: parent.right
      anchors.rightMargin: 5
      anchors.top: parent.top
      anchors.topMargin: 10
      text: "West"
      color: "black"
      font.pixelSize: 28
    }
  }


  // the four playerHands placed around the main game field
  Item {
    id: playerHands
    anchors.fill: gameWindowAnchorItem

    Text {
      id: bottomHand
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      z: 100
      text: "s"
    }

    Text {
      id: leftHand
      anchors.left: parent.left
      anchors.leftMargin: -width/2 + height/2
      anchors.verticalCenter: parent.verticalCenter
      rotation: 90
      text: "e"
    }

    Text {
      id: topHand
      anchors.top: parent.top
      anchors.left: parent.left
      rotation: 180
      text: "n"
    }

    Text {
      id: rightHand
      anchors.right: parent.right
      anchors.rightMargin: -width/2 + height/2
      anchors.top: parent.top
      rotation: 270
      text: "w"
    }
  }

//  Card2 {
//  }
//  Card2 {
//     anchors.bottom: gameScene.gameWindowAnchorItem.bottom
//  }
//  Card2 {
//     anchors.bottom: gameScene.gameWindowAnchorItem.bottom
//     anchors.right: gameScene.gameWindowAnchorItem.right
//  }

//  Card2 {
//     anchors.right: gameScene.gameWindowAnchorItem.right
//  }
}
