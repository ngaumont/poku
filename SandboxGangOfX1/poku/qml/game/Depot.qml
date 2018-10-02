import QtQuick 2.0
import VPlay 2.0

Item {
  id: depot



  // current card on top of the depot for finding a match
  property var current: null
  // whether the active player is skipped or not
  property bool skipped: false
  // the current turn direction
  property bool clockwise: true



  // return a random number between two values
  function randomIntFromInterval(min,max)
  {
    return Math.floor(Math.random() * (max - min + 1) + min)
  }

  // add the selected card to the depot
  function depositCard(cardId){
    var card = entityManager.getEntityById(cardId)
    // change the parent of the card to depot
    changeParent(card)
    // uncover card right away if the player is connected
    // used for wild and wild4 cards
    // activePlayer might be undefined here, when initially synced
    if (!multiplayer.activePlayer || multiplayer.activePlayer.connected){
      card.hidden = false
    }

    // move the card to the depot and vary the position and rotation
    var rotation = randomIntFromInterval(-5, 5)
    var xOffset = randomIntFromInterval(-20, 20)
    var yOffset = randomIntFromInterval(-20, 20)
    card.rotation = rotation
    card.x = depot.x+ xOffset
    card.y = depot.y + yOffset

    // the first card starts with z 0, the others get placed on top
    if (!current) {
      card.z = 0
    }else{
      card.z = current.z + 1
    }

    // the deposited card is the current reference card
    current = card

    var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0

    // signal if the placed card has an effect on the next player
      multiplayer.sendMessage(gameLogic.messageSetEffect, {effect: false, userId: userId})

  }

// change the card's parent to depot
function changeParent(card){
  card.newParent = depot
  card.state = "depot"
}

  // check if the selected card matches with the current reference card
  function validCard(cardId){
      return true
    // only continue if the selected card is in the hand of the active player
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player === multiplayer.activePlayer){
        if (!playerHands.children[i].inHand(cardId)) return false
      }
    }
    var card = entityManager.getEntityById(cardId)
 return true
  }

}
