import VPlay 2.0
import QtQuick 2.0
import "../common"
import "../game"

SceneBase {
  id:gameScene

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
     anchors.right: gameScene.gameWindowAnchorItem.right
     anchors.rightMargin: 10
     anchors.top: gameScene.gameWindowAnchorItem.top
     anchors.topMargin: 10
     onClicked: backButtonPressed()
   }



  Card2 {
  }
  Card2 {
     anchors.bottom: gameScene.gameWindowAnchorItem.bottom
  }
  Card2 {
     anchors.bottom: gameScene.gameWindowAnchorItem.bottom
     anchors.right: gameScene.gameWindowAnchorItem.right
  }

  Card2 {
     anchors.right: gameScene.gameWindowAnchorItem.right
  }
}
