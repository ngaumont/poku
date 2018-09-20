import QtQuick 2.0
import VPlay 2.0

// the cards in the hand of the player
Item {
  id: playerHand

  property double zoom: 1.0

  // amount of cards in hand in the beginning of the game
  property int start: 16
  // array with all cards in hand
  property var hand: []


  // the owner of the cards
  //Hardcoded and replace inside GameScene
  property int player: 0

  // the score at the end of the game
  property int score: 0



  // sound effect plays when drawing a card
//  SoundEffectVPlay {
//    volume: 0.5
//    id: drawSound
//    source: "../../assets/snd/draw.wav"
//  }

//  // sound effect plays when depositing a card
//  SoundEffectVPlay {
//    volume: 0.5
//    id: depositSound
//    source: "../../assets/snd/deposit.wav"
//  }

//  // sound effect plays when winning the game
//  SoundEffectVPlay {
//    volume: 0.5
//    id: winSound
//    source: "../../assets/snd/win.wav"
//  }


  // start the hand by picking up a specified amount of cards
  function startHand(){
    pickUpCards(start)
  }
  function consoleDisplay(){
      for (var i = 0; i < hand.length; i ++){
        console.log(hand[i].literalRepresentation())
      }
  }

  // reset the hand by removing all cards
  function reset(){
    while(hand.length) {
      hand.pop()
    }
  }

  // organize the hand and spread the cards
  function neatHand(){
    // sort all cards by their natural order
    hand.sort(function(a, b) {
      return a.order - b.order
    })

    // calculate the card position and rotation in the hand and change the z order
    for (var i = 0; i < hand.length; i ++){
      var card = hand[i]
      var line_num = Math.floor(i/4)
      card.y = 225 + line_num * 50
      card.x = (4- line_num)*15 + i%4 * 60
      card.z = i + 50
    }
  }

  // pick up specified amount of cards
  function pickUpCards(amount){
    var pickUp = deck.handOutCards(amount)
    // add the stack cards to the playerHand array
    for (var i = 0; i < pickUp.length; i ++){
      hand.push(pickUp[i])
      changeParent(pickUp[i])
//      if (multiplayer.localPlayer == player){
        pickUp[i].hidden = false
        pickUp[i].visible = true

//      }
    }
    // reorganize the hand
    neatHand()
  }

  // change the current hand card array
//  function syncHand(cardIDs) {
//    hand = []
//    for (var i = 0; i < cardIDs.length; i++){
//      var tmpCard = entityManager.getEntityById(cardIDs[i])
//      hand.push(tmpCard)
//      changeParent(tmpCard)
//      deck.cardsInStack --
//      if (multiplayer.localPlayer == player){
//        tmpCard.hidden = false
//      }
//    }
//    // reorganize the hand
//    neatHand()
//  }

  // change the parent of the card to playerHand
  function changeParent(card){
    card.newParent = playerHand
    card.state = "player"
  }

  // check if a card with a specific id is on this hand
  function inHand(cardId){
    for (var i = 0; i < hand.length; i ++){
      if(hand[i].entityId === cardId){
        return true
      }
    }
    return false
  }

  // remove card with a specific id from hand
  function removeFromHand(cardId){
    for (var i = 0; i < hand.length; i ++){
      if(hand[i].entityId === cardId){
        hand.splice(i, 1)
        neatHand()
        return
      }
    }
  }

  // highlight all valid cards by setting the glowImage visible
//  function markValid(){
//    if (!depot.skipped && !gameLogic.gameOver && !colorPicker.chosingColor){
//      for (var i = 0; i < hand.length; i ++){
//        if (depot.validCard(hand[i].entityId)){
//          hand[i].glowImage.visible = true
//          hand[i].updateCardImage()
//        }else{
//          hand[i].glowImage.visible = false
//          hand[i].saturation = -0.5
//          hand[i].lightness = 0.5
//        }
//      }
//      // mark the stack if there are no valid cards in hand
//      var validId = randomValidId()
//      if(validId == null){
//        deck.markStack()
//      }
//    }
//  }

  // unmark all cards in hand
//  function unmark(){
//    for (var i = 0; i < hand.length; i ++){
//      hand[i].glowImage.visible = false
//      hand[i].updateCardImage()
//    }
//  }

  // scale the whole playerHand of the active localPlayer with a zoom factor
//  function scaleHand(scale){
//    zoom = scale
//    playerHand.height = playerHand.originalHeight * zoom
//    playerHand.width = playerHand.originalWidth * zoom
//    for (var i = 0; i < hand.length; i ++){
//      hand[i].width = hand[i].originalWidth * zoom
//      hand[i].height = hand[i].originalHeight * zoom
//    }
//    neatHand()
//  }

  // get a random valid card id from the playerHand

  // check if the player has won with zero cards left
  function checkWin(){
    if (hand.length == 0){
      return true
    }else{
      return false
    }
  }

  // calculate all card points in hand
  function points(){
    var points = 0
    return points
  }
}
