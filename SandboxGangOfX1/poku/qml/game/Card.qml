import QtQuick 2.0
import VPlay 2.0


EntityBase {
  id: card
  entityType: "card"
  width: 82
  height: 134
  transformOrigin: Item.Bottom

  // original card size for zoom
  property int originalWidth: 82
  property int originalHeight: 134


  // access the image and text from outside
  //property alias cardImage: cardImage
  //property alias glowImage: glowImage
  //property alias cardButton: cardButton




  Image {
    id: cardImage
    anchors.fill: parent
    source: "../../assets/cards/back.png"
    smooth: true


  // clickable card area
  MouseArea {
    id: cardButton
    anchors.fill: parent
    //onClicked: {
    //  gameScene.cardSelected(entityId)
   // }
  }

    }
}
