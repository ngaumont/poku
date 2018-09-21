import VPlay 2.0
import QtQuick 2.0

Item {

    id: playerTag

//     width:130

    property string name

    // The owner of the tag
    // hard coded inside gameScene for now
    property int player: 0



    // username text
    Text {
      id: name
      text: parent.name
      // make as big that a typical player text like "Player 1234567" fits into the width
      font.pixelSize: 28
      color: "black"
//      anchors.top: parent.bottom
      anchors.topMargin: 3
      anchors.horizontalCenter: parent.horizontalCenter


      // displays the detailed playerInfoPopup
      MouseArea {
        id: dispCard
        anchors.fill: parent
        enabled: true
        onClicked: {
          console.log(parent.text)
            for (var i = 0; i < playerHands.children.length; i++) {
              // start the hand for each player
              playerHands.children[i].visible = false

              if(playerHands.children[i].player == player){
                  playerHands.children[i].visible = true
              }
            }
        }
      }
    }
}
