import VPlay 2.0
 import QtQuick 2.0
 import "../common"

 SceneBase {
   id:creditsScene

   // background
   Rectangle {
     anchors.fill: parent.gameWindowAnchorItem
     color: "#49a349"
   }


   Text {
     anchors.horizontalCenter: parent.horizontalCenter
     y: 30
     font.pixelSize: 30
     color: "#e9e9e9"
     text: "No^2 et Co^2"
   }


   MenuButton {
      text: "Back"
      anchors.right: creditsScene.gameWindowAnchorItem.right
      anchors.rightMargin: 10
      anchors.top: creditsScene.gameWindowAnchorItem.top
      anchors.topMargin: 10
      onClicked: backButtonPressed()
    }

 }
