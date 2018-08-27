import VPlay 2.0
import QtQuick 2.0
import "../common"
import "../game"

SceneBase {
  id:gameScene

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
