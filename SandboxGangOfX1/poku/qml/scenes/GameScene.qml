import VPlay 2.0
import QtQuick 2.0
import "../common"
import "../game"
import "../interface"

SceneBase {
  id:gameScene

  property alias deck: deck
  property alias depot: depot
  property alias gameLogic: gameLogic

  // game signals
  signal cardSelected(var cardId)

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
    color: "#eae3ce"
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

  Depot {
    id: depot
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter:  parent.verticalCenter
    anchors.verticalCenterOffset: -100
    //Rectangle {
    //  width : 120
    //  height: 100
    //  anchors.horizontalCenter: parent.horizontalCenter
    //  anchors.verticalCenter: parent.verticalCenter
    //  border.color : "black"
    //  border.width: 2
    //  color: "transparent"
    //}

  }
  // the playerTags for each playerHand
  Item {
    id: playerTags
    anchors.fill: gameWindowAnchorItem

    PlayerTag {
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 40
      anchors.right: parent.right
      anchors.rightMargin: 45
      name: "South"
      player:0
    }

    PlayerTag {
      anchors.left: parent.left
      anchors.leftMargin: 30
      anchors.top: parent.top
      anchors.topMargin: 125
      name: "West"
      player:1
    }

    PlayerTag {
      anchors.top: parent.top
      anchors.topMargin: 10
      anchors.left: parent.left
      anchors.leftMargin: 40
      name: "North"
      player:2
    }

    PlayerTag {
      id: rightPlayerTag
      anchors.right: parent.right
      anchors.rightMargin: 40
      anchors.top: parent.top
      anchors.topMargin: 10
      name: "East"
      player:3
    }
  }


  // the four playerHands placed around the main game field
  Item {
    id: playerHands
    anchors.fill: gameWindowAnchorItem

    PlayerHand {
      id: bottomHand
      player:0
      visible: true
    }

    PlayerHand {
      id: leftHand
      player:1
      visible:false
    }

    PlayerHand {
      id: topHand
      player:2
      visible:false
    }

    PlayerHand {
      id: rightHand
      player:3
      visible:false
    }
  }

}
