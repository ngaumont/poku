import VPlay 2.0
import QtQuick 2.0
import "../common"

SceneBase {
  id:menuScene

  // background
  Rectangle {
    anchors.fill: parent.gameWindowAnchorItem
    color: "#47688e"
  }

  // the "logo"
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    y: 30
    font.pixelSize: 30
    color: "#e9e9e9"
    text: "Poku Gang of X"
  }

    // signal indicating that the selectLevelScene should be displayed
    signal quickGamePressed
    // signal indicating that the creditsScene should be displayed
    signal creditsPressed

    signal selectLevelPressed

    //...

    // menu
    Column {
      anchors.centerIn: parent
      spacing: 6
      MenuButton {
        text: "Quick game"
        onClicked: quickGamePressed()
      }
      MenuButton {
        text: "Credits"
        onClicked: creditsPressed()
      }
    }
  }


