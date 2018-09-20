import QtQuick 2.0
import VPlay 2.0
import "../scenes"
import "../game"


EntityBase {
  id: card
  entityType: "card"
  width: 44
  height: 44
  transformOrigin: Item.Bottom

  // original card size for zoom
  property int originalWidth: 44
  property int originalHeight: 44


  property int level: 0
//  property int points: 50
  property int cardColor: 0
  property int order

  // access the image and text from outside
  //property alias cardImage: cardImage
  //property alias glowImage: glowImage
  //property alias cardButton: cardButton

  // hidden cards show the back side
  // you could also offer an in-app purchase to show the cards of a player for example!
  property bool hidden: !forceShowAllCards

  visible: !forceShowAllCards

  // to show all cards on the screen and to test multiplayer syncing, set this to true
  // it is useful for testing, thus always enable it for debug builds and non-publish builds
  property bool forceShowAllCards: system.debugBuild && !system.publishBuild


  // used to reparent the cards at runtime
  property var newParent

  function literalRepresentation(){
    return gameScene.deck.levelLit[this.level] + " " + gameScene.deck.cardColorLit[this.cardColor]
  }

  Image {
    id: cardImage
    anchors.fill: parent
    source: "../../assets/cards/back.png"
    smooth: true


  // clickable card area
  MouseArea {
    id: cardButton
    anchors.fill: parent
    onClicked: {
      console.log(card.literalRepresentation())
    }
  }

    }
}
