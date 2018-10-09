import QtQuick 2.0
import VPlay 2.0

Item {
  id: gameLogic

  property bool singlePlayer: false
  property bool initialized: false
  onInitializedChanged: console.debug("GameLogic.initialized changed to:", initialized)
  // the remaining turn time for the active player
  property double remainingTime
  // turn time for the active player, in seconds
  // do not set this too low, otherwise players with higher latency could run into problems as they get skipped by the leader
  property int userInterval: 5 //multiplayer.myTurn && !multiplayer.amLeader ? 7 : 10
  // turn time for AI players, in milliseconds
  property int aiTurnTime: 600
  // restart the game at the end after a few seconds
  property int restartTime: 8000
  // whether the user has already drawn cards this turn or not
  property bool acted: false
  property bool gameOver: false

  property int messageSyncGameState: 0
  property int messageRequestGameState: 1
  property int messageMoveCardsHand: 2
  property int messageMoveCardsDepot: 3
  property int messageSetEffect: 4
  property int messageSetSkipped: 5
  property int messageSetReverse: 6
  property int messageSetDrawAmount: 7
  property int messagePickColor: 8
  property int messagePressONU: 9
  property int messageEndGame: 10 // we could replace this custom message with the new endGame() function from multiplayer, custom end game message was sent before this functionality existed
  property int messagePrintChat: 11
  property int messageSetPlayerInfo: 12
  property int messageTriggerTurn: 13
  property int messageRequestPlayerTags: 14

  // gets set to true when a message is received before the game state got synced. in that case, request a new game state
  property bool receivedMessageBeforeGameStateInSync: false

  // bling sound effect when selecting a color for wild or wild4 cards

  // connect to the VPlayMultiplayer object and handle all messages
  Connections {
    // this is important! only handle the messages when we are currently in the game scene
    // otherwise, we would handle the playerJoined signal when the player is still in matchmaking view!
    // do not use the visible property here! as visible only gets triggered with the opacity animation in SceneBase
    target: multiplayer
    enabled: activeScene === gameScene

    onGameStarted: {
      // the gameStarted signal is received by the client as well not only by the leader, otherwise we would not realize when a new game starts
      // otherwise only the leader would trigger a "User.RestartGame" event
      // this is called internally though, thus make it a system event
      if(gameRestarted) {
      } else {
      }
    }

    onAmLeaderChanged: {
      if (multiplayer.leaderPlayer){
        console.debug("Current Leader is: " + multiplayer.leaderPlayer.userId)
      }
      if(multiplayer.amLeader) {
        console.debug("this player just became the new leader")
        if(!timer.running && !gameOver) {
          console.debug("New leader selected, but the timer is currently not running, thus trigger a new turn now")
          // even when we comment this, the game does not stall 100%, thus it is likely that we would skip a player here. but better to skip a player once and make sure the game is continued than stalling the game. hard to reproduce, as it does not happen every time the leader changes!
          triggerNewTurn()
        } else if (!timer.running){
          restartGameTimer.start()
        }
      }
    }

    onMessageReceived: {
      console.debug("onMessageReceived with code", code, "initialized:", initialized)
      // not relevant for google analytics, causes to exceed the free limit
      //ga.logEvent("System", "Receive Message", "singlePlayer", multiplayer.singlePlayer)

      if(!initialized && code !== messageSyncGameState) {
        console.debug("ERROR: received message before gameState was synced and user is not initialized:", code, message)

        if (message.receiverPlayerId === multiplayer.localPlayer.userId && !compareGameStateWithLeader(message.playerHands)) {
          receivedMessageBeforeGameStateInSync = true
        }
        return
      }

      // sync the game state for existing and newly joined players
      if (code == messageSyncGameState) {
        if (!message.receiverPlayerId || message.receiverPlayerId === multiplayer.localPlayer.userId || !compareGameStateWithLeader(message.playerHands)) {
          console.debug("Sync Game State now")
          console.debug("Received Message: " + JSON.stringify(message))
          // NOTE: the activePlayer can be undefined here, when the player makes a late-join! thus add a check in syncDepot() -> depositCard() and handle the case that it is undefined!
          console.debug("multiplayer.activePlayer when syncing game state:", multiplayer.activePlayer)

          syncPlayers()
          initTags()
          syncDeck(message.deck)
          depot.syncDepot(message.depot, message.current, message.currentCardColor, message.skipped, message.clockwise, message.effect, message.drawAmount)
          syncHands(message.playerHands)

          // join a game which is already over
          gameOver = message.gameOver
          gameScene.gameOver.visible = gameOver
          timer.running = !gameOver

          console.debug("finished syncGameState, setting initialized to true now")
          initialized = true

          // if we before received a message before game state was in sync, do request a new game state from the leader now
          if(receivedMessageBeforeGameStateInSync) {
            console.debug("requesting a new game state from server now, as receivedMessageBeforeGameStateInSync was true")
            multiplayer.sendMessage(messageRequestGameState, multiplayer.localPlayer.userId)
            receivedMessageBeforeGameStateInSync = false
          }

          // request the detailed playerTag info from the other players (highscore, level and badge)
          // if the message was specifically sent to the local user (for example when he or she joins)
          if (message.receiverPlayerId){
            multiplayer.sendMessage(messageRequestPlayerTags, multiplayer.localPlayer.userId)
          }
        }
      }
      // send a new game state to the requesting user
      else if (code == messageRequestGameState){
        multiplayer.leaderCode(function() {
          sendGameStateToPlayer(message)
        })
      }
      // move card to hand
      else if (code == messageMoveCardsHand){
        // if there is an active player with a different userId, the message is invalid
        // the message was probably sent after the leader triggered the next turn
        if (multiplayer.activePlayer && multiplayer.activePlayer.userId != message.userId){
          multiplayer.leaderCode(function() {
            sendGameStateToPlayer(message.userId)
          })
          return
        }

        getCards(message.cards, message.userId)
      }
      // move card to depot
      else if (code == messageMoveCardsDepot){
        // if there is an active player with a different userId, the message is invalid
        // the message was probably sent after the leader triggered the next turn
        if (multiplayer.activePlayer && multiplayer.activePlayer.userId != message.userId){
          multiplayer.leaderCode(function() {
            sendGameStateToPlayer(message.userId)
          })
          return
        }

        depositCard(message.cardId, message.userId)
      }
      // lasting card effect
      else if (code == messageSetEffect){
        // if the message wasn't sent by the leader and
        // if it wasn't sent by the active player, the message is invalid
        // the message was probably sent after the leader triggered the next turn
        if (multiplayer.leaderPlayer.userId != message.userId &&
            multiplayer.activePlayer && multiplayer.activePlayer.userId != message.userId){
          return
        }

        depot.effect = message.effect
      }
      // sync skipped state
      else if (code == messageSetSkipped){
        // if the message wasn't sent by the leader and
        // if it wasn't sent by the active player, the message is invalid
        // the message was probably sent after the leader triggered the next turn
        if (multiplayer.leaderPlayer.userId != message.userId &&
            multiplayer.activePlayer && multiplayer.activePlayer.userId != message.userId){
          return
        }

        depot.skipped = message.skipped
      }
      // sync turn direction
      else if (code == messageSetReverse){
        // if the message wasn't sent by the leader and
        // if it wasn't sent by the active player, the message is invalid
        // the message was probably sent after the leader triggered the next turn
        if (multiplayer.leaderPlayer.userId != message.userId &&
            multiplayer.activePlayer && multiplayer.activePlayer.userId != message.userId){
          return
        }

        depot.clockwise = message.clockwise
      }
      // current drawAmount
      else if (code == messageSetDrawAmount){
        // if the message wasn't sent by the leader and
        // if it wasn't sent by the active player, the message is invalid
        // the message was probably sent after the leader triggered the next turn
        if (multiplayer.leaderPlayer.userId != message.userId &&
            multiplayer.activePlayer && multiplayer.activePlayer.userId != message.userId){
          return
        }

        depot.drawAmount = message.amount
      }
      // wild color picked
      else if (code == messagePickColor){
        // if the message wasn't sent by the leader and
        // if it wasn't sent by the active player, the message is invalid
        // the message was probably sent after the leader triggered the next turn
        if (multiplayer.leaderPlayer.userId != message.userId &&
            multiplayer.activePlayer && multiplayer.activePlayer.userId != message.userId){
          return
        }

        pickColor(message.color)
      }
      // someone pressed onu
      else if (code == messagePressONU){
        var playerHand = getHand(message.userId)
        if (playerHand) {
          playerHand.onu = message.onu
        }
      }
      // game ends
      else if (code == messageEndGame){
        // if the message wasn't sent by the leader and
        // if it wasn't a desktop test and
        // if it wasn't sent by the active player, the message is invalid
        // the message was probably sent after the leader triggered the next turn
        if (multiplayer.leaderPlayer.userId != message.userId &&
            multiplayer.activePlayer && multiplayer.activePlayer.userId != message.userId && !message.test){
          return
        }

        endGame(message.userId)
      }
      // chat message
      else if (code == messagePrintChat){
        if (!chat.gConsole.visible){
          chat.chatButton.buttonImage.source = "../../assets/img/Chat2.png"
        }
        chat.gConsole.printLn(message)
      }
      // set highscore and level from other players
      else if (code == messageSetPlayerInfo){
        updateTag(message.userId, message.level, message.highscore, message.rank)
      }
      // let the leader trigger a new turn
      else if (code == messageTriggerTurn){
        multiplayer.leaderCode(function() {
          // the leader only stops the turn early if the requesting user is still the active player
          if (multiplayer.activePlayer && multiplayer.activePlayer.userId == message){
            triggerNewTurn()
          }
          // if the requesting user is no longer active, it means that he timed out according to the leader
          // his last action happened after his turn and is therefore invalid
          // the leader has to send the user a new game state
          else {
            sendGameStateToPlayer(message)
          }
        })
      }
      // reset player tag info and send it to other player because it was requested
      /*
         Only the local user can access their highscore and rank from the leaderboard.
         This is the reason why we sync this information with messageSetPlayerInfo messages.
         Late join users have to request this information again after they initialize the game with a messageSyncGameState message.
         Another option would be to let the leader send highscore, rank and level of each user via messageSyncGameState.
      */
      else if (code == messageRequestPlayerTags){
        initTags()
      }
    }
  }

  // connect to the gameScene and handle all signals
  Connections {
    target: gameScene

    // the player selected the stack
    onStackSelected: {
      // draw cards if it is the player's turn
      if (multiplayer.myTurn && !depot.skipped && !acted && !cardsDrawn) {
        if (hasValidCards(multiplayer.localPlayer)){
          acted = true
        }

        var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
        getCards(depot.drawAmount, userId)
        multiplayer.sendMessage(messageMoveCardsHand, {cards: depot.drawAmount, userId: userId})

        if (acted || !hasValidCards(multiplayer.localPlayer)){
          acted = true
          endTurn()
        } else {
          // reset the drawAmount during the player's turn
          depot.drawAmount = 1
          depot.effect = false
          multiplayer.sendMessage(gameLogic.messageSetDrawAmount, {amount: 1, userId: userId})

          // scale and mark the newly aquired cards according to the playerHand
          scaleHand(1.6)
          markValid()
          // check if the player has two or less cards left
          closeToWin()
        }

        // not relevant for google analytics, causes to exceed the free limit
        //ga.logEvent("User", "Stack Selected", "singlePlayer", multiplayer.singlePlayer)
//        flurry.logEvent("User.StackSelected", "singlePlayer", multiplayer.singlePlayer)
      }
    }

    // the player selected or deselected a card
    onCardSelected: {
        var card = entityManager.getEntityById(cardId)
        card.isSelected = !card.isSelected
    }

    onCardsPlayed: {

//        if (depot.validCard(cardId)){
//
//            depositCard(cardId, multiplayer.localPlayer.userId)
//        }


        playCards(getSelectedCards(), multiplayer.localPlayer.userId)

  }
}

  function getCardCombinationType(cards)
  {
     // 0 crap
     // 1 single card
     // 2


     if (cards == null || cards.length == 0){return ["crap"]}

     cards.sort(function(a, b) {
           return a.order - b.order
         })


     if (cards.length ==1) {return ["single"]}

     var areCardsNPair = true
     var pairLevel = cards[0].level
     for (var i = 0; i < cards.length; i++) {
          if (cards[i].level != pairLevel){
            areCardsNPair = false
            break
          }
     }

     if (cards.length ==2 && areCardsNPair) {return ["double"]}

     if (cards.length ==3 && areCardsNPair) {return ["triple"]}

     //Gang of fours
     if (cards.length >4 && areCardsNPair) {return ["carre"],cards.length}

     if (cards.length == 5)
     {
        if (cards[4].level <11 && cards[4].level ==cards[3].level+1 && cards[3].level ==cards[2].level+1 &&cards[2].level ==cards[1].level+1 &&cards[1].level ==cards[0].level+1 &&
                cards[4].cardColor == cards[3].cardColor && cards[3].cardColor == cards[2].cardColor && cards[2].cardColor == cards[1].cardColor && cards[1].cardColor == cards[0].cardColor)
               { return ["Five", 5 ]}
        if ((cards[4].level ==cards[2].level && cards[1].level ==cards[0].level) ||
                (cards[4].level ==cards[3].level && cards[2].level ==cards[0].level))
               { return ["Five", 4 , cards[2].level]}
        if (cards[4].cardColor == cards[3].cardColor && cards[3].cardColor == cards[2].cardColor && cards[2].cardColor == cards[1].cardColor && cards[1].cardColor == cards[0].cardColor)
        {
                return ["Five", 3 ]
        }
        if (cards[4].level <11 && cards[4].level ==cards[3].level+1 && cards[3].level ==cards[2].level+1 &&cards[2].level ==cards[1].level+1 &&cards[1].level ==cards[0].level+1)
        {
                return ["Five", 2 ]
        }
        return "crap"
     }

     return "crap"
  }

  function canCardBePlayed(selectedCards,currentDepot){
      //console.debug(depot.current)
      //console.debug(selectedCards)
      //console.debug(selectedCards.length)
      var cardCombination = getCardCombinationType(selectedCards)

      // to play, one need a valid combination: single, double ...
      if (cardCombination[0]=="crap"){return false}

      var depotCombination = getCardCombinationType(currentDepot)
      console.debug(cardCombination.toString() + " vs " + depotCombination.toString())

      //The first player to play can place any valid combination if depot is empty
      if (currentDepot == null) return true

      //If cards have already been played, we have to play the same combination type or a carre
      if (cardCombination[0] == depotCombination[0]){
          if (cardCombination[0] == "five")
          {
            //quint<flush<full<quint flush
            if (cardCombination[1] > depotCombination[1]){return true}
            if (cardCombination[1] < depotCombination[1]){return false}
            //level of triple of full is what matters
            if (cardCombination[2]>depotCombination[2]) {return true}
            if (cardCombination[2]<depotCombination[2]) {return false}
          }
          if (cardCombination[0] == "carre")
          {// length of carre is what matters
            if (cardCombination[1] > depotCombination[1]){return true}
            if (cardCombination[1] < depotCombination[1]){return false}
          }

          //else need to compare cards 1 by one
          for (var i = selectedCards.length-1; i >= 0; i++) {
              console.debug(selectedCards[i])
              if (selectedCards[i].level > currentDepot[i].level){return true}
              if (selectedCards[i].level < currentDepot[i].level){return false}
              if (selectedCards[i].cardColor> currentDepot[i].cardColor){return true}
              if (selectedCards[i].cardColor< currentDepot[i].cardColor){return false}
          }
          //Same cards being played
          return false
      }

      //if we arrive here, we know for sure that NOT both cards and depot are care
      if (cardCombination == "carre") {return true}
  }

  function getSelectedCards()
  {
      var cards = entityManager.getEntityArrayByType("card")
      var selectedCards = []
      console.debug("Card(s) played:")
      for (var i = 0; i < cards.length; i++) {
          if (cards[i].isSelected){
              selectedCards.push(cards[i])
              console.debug(cards[i].literalRepresentation())
          }
        }
      return selectedCards
  }

  function playCards(selectedCards, userId){
      if (canCardBePlayed(selectedCards,depot.current)){

          for (var i = 0; i < selectedCards.length; i++) {
              selectedCards[i].isSelected = false
              depositCard(selectedCards[i].entityId, multiplayer.localPlayer.userId)

              }
          depot.current = selectedCards
      }

  }

  // sync deck with leader and set up the game
  function syncDeck(cardInfo){
    console.debug("syncDeck()")
    deck.syncDeck(cardInfo)
    // takes off 1st card
    depot.createDepot()

    // reset all values at the start of the game
    gameOver = false
    timer.start()
    scaleHand()
    markValid()
    gameScene.gameOver.visible = false
    gameScene.leaveGame.visible = false
    gameScene.switchName.visible = false
    playerInfoPopup.visible = false
    onuButton.button.enabled = false
    chat.reset()
  }

  // deposit the selected card
  function depositCard(cardId, userId){
    // unmark all highlighted cards
    //unmark()
    // scale down the active localPlayer playerHand
    scaleHand(1.0)
    for (var i = 0; i < playerHands.children.length; i++) {
      // find the playerHand for the active player
      // if the selected card is in the playerHand of the active player
      if (playerHands.children[i].inHand(cardId)){
        // remove and deposit the card
        playerHands.children[i].removeFromHand(cardId)
        depot.depositCard(cardId)


      }
    }
  }

  // let AI take over if the player is not skipped
  function executeAIMove() {
    if(!depot.skipped){
      playRandomValid()
    }
  }

  // play a random valid card from the playerHand of the active player
  function playRandomValid() {
    // find the playerHand of the active player
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player === multiplayer.activePlayer && !cardsDrawn){
        var validCardId = playerHands.children[i].randomValidId()
        var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
        // deposit the valid card or draw cards from the stack
        if (validCardId){
          multiplayer.sendMessage(messageMoveCardsDepot, {cardId: validCardId, userId: userId})
          depositCard(validCardId, userId)

          if (depot.current.variationType === "draw2") depot.draw(2)
          if (depot.current.variationType === "wild4") depot.draw(4)
          // let the ai only draw cards if the user hasn't already done it
        } else {
          getCards(depot.drawAmount, userId)
          multiplayer.sendMessage(messageMoveCardsHand, {cards: depot.drawAmount, userId: userId})
        }
      }
    }
  }

  // check whether a user with a specific id has valid cards or not
  function hasValidCards(userId){
    var playerHand = getHand(multiplayer.localPlayer.userId)
    var valids = playerHand.getValidCards()
    return valids.length > 0
  }

  // give the connected player 10 seconds until the AI takes over
  function startTurnTimer() {
    timer.stop()
    // 7 seconds
    remainingTime = userInterval
    if (!gameOver) {
      timer.start()
      scaleHand()
      markValid()
    }
  }

  // start the turn for the active player
  function turnStarted(playerId) {
    console.debug("turnStarted() called")

    if(!multiplayer.activePlayer) {
      console.debug("ERROR: activePlayer not valid in turnStarted!")
      return
    }

    console.debug("multiplayer.activePlayer.userId: " + multiplayer.activePlayer.userId)
    console.debug("Turn started")
    // start the timer
    gameLogic.startTurnTimer()
    // the player didn't act yet
    acted = false
    cardsDrawn = false
    unmark()
    scaleHand(1.0)
    // reset the colorPicker
    colorPicker.visible = false
    colorPicker.chosingColor = false
    // check if the current card has an effect for the active player
    depot.cardEffect()
    // zoom in on the hand of the active local player
    if (!depot.skipped && multiplayer.myTurn) scaleHand(1.6)
    // check if the player has two or less cards left
    closeToWin()
    // mark the valid card options
    markValid()
    // repaint the timer circle
    for (var i = 0; i < playerTags.children.length; i++){
      playerTags.children[i].canvas.requestPaint()
    }
    // schedule AI to take over in 3 seconds in case the player is gone
    multiplayer.leaderCode(function() {
      if (!multiplayer.activePlayer || !multiplayer.activePlayer.connected) {
        aiTimeOut.start()
      }
    })
  }

  // schedule AI to take over after 10 seconds if the connected player is inactive
  function turnTimedOut(){
    if (multiplayer.myTurn && !acted){
      acted = true
      scaleHand(1.0)
    }
    // clean up our UI
    timer.running = false
    // player timed out, so leader should take over
    multiplayer.leaderCode(function () {
      // if the player is in the process of chosing a color
      if (!colorPicker.chosingColor){
        // play an AI bone if this player never played anything (this happens in the case where the player left some time during his turn, and so the early 3 second AI move didn't get scheduled
        executeAIMove()
      }
      endTurn()
    })
  }

  function createGame(){
    multiplayer.createGame()
  }

  // stop the timers and reset the deck at the end of the game
  function leaveGame(){
    aiTimeOut.stop()
    restartGameTimer.stop()
    timer.running = false
    depot.effectTimer.stop()
    deck.reset()
    chat.gConsole.clear()
    multiplayer.leaveGame()
    scaleHand(1.0)
    initialized = false
    receivedMessageBeforeGameStateInSync = false
      /*
    ga.logEvent("User", "Exit Game", "singlePlayer", multiplayer.singlePlayer)
    flurry.logEvent("User.ExitGame", "singlePlayer", multiplayer.singlePlayer)
    flurry.endTimedEvent("Game.TimeInGameTotal", {"singlePlayer": multiplayer.singlePlayer})*/
  }

  function joinGame(room){
    multiplayer.joinGame(room)
  }

  // initialize the game
  // is called from GameOverWindow when the leader restarts the game, and from GameScene when it got visible from GameScene.onVisibleChanged
  function initGame(calledFromGameOverScreen){

    // initialize the players, the deck and the individual hands
    initPlayers()
    initDeck()
    initHands()

      for (var i = 0; i < playerHands.children.length; i++) {
        // start the hand for each player
        playerHands.children[i].reset()
        playerHands.children[i].startHand()
        playerHands.children[i].unmark()
      }

      console.debug("InitGame finished!")
  }

  /*
    Is only called if leader. The leader does not receive the messageSyncGameState message anyway, because messages are not sent to self.
    Used to sync the game in the beginning and for every newly joined player.
    Is called from leader initially when starting a game and when a new player joins.
    If playerId is undefined, it is handled by all players. Use this for initial syncing with players already in the matchmaking room.
  */
  function sendGameStateToPlayer(playerId) {
    console.debug("sendGameStateToPlayer() with playerId", playerId)
    // save all needed game sync data
    var message = {}

    // save all current hands of the other players
    var currentPlayerHands = []
    for (var i = 0; i < playerHands.children.length; i++) {
      // the hand of a single player
      var currentPlayerHand = {}
      // save the userId to assign the information to the correct player
      currentPlayerHand.userId = playerHands.children[i].player.userId
      // save the ids of player's cards
      currentPlayerHand.handIds = []
      for (var j = 0; j < playerHands.children[i].hand.length; j++){
        currentPlayerHand.handIds[j] = playerHands.children[i].hand[j].entityId
      }
      // add the hand information of a single player
      currentPlayerHands.push(currentPlayerHand)
    }
    // save the hand information of all players
    message.playerHands = currentPlayerHands
    // save the deck information to create an identical one
    message.deck = deck.cardInfo
    // sync the depot variables
    message.current = depot.current.entityId
    message.currentCardColor = depot.current.cardColor

    message.skipped = depot.skipped
    message.clockwise = depot.clockwise
    message.effect = depot.effect
    message.drawAmount = depot.drawAmount
    message.gameOver = gameOver

    // save all card ids of the current depot
    var depotIDs = []
    for (var k = 0; k < deck.cardDeck.length; k++){
      if (deck.cardDeck[k].state === "depot" && deck.cardDeck[k].entityId !== depot.current.entityId){
        depotIDs.push(deck.cardDeck[k].entityId)
      }
    }
    message.depot = depotIDs

    // send the message to the newly joined player
    message.receiverPlayerId = playerId

    console.debug("Send Message: " + JSON.stringify(message))
    multiplayer.sendMessage(messageSyncGameState, message)
  }

  // compares the amount of cards in each player's hand with the leader's game state
  // used to check whether to sync with the leader or not
  function compareGameStateWithLeader(messageHands){
    for (var i = 0; i < playerHands.children.length; i++){
      var currentUserId = playerHands.children[i].player.userId
      for (var j = 0; j < messageHands.length; j++){
        var messageUserId = messageHands[j].userId
        if (currentUserId == messageUserId){
          if (playerHands.children[i].hand.length != messageHands[j].handIds.length){
            // returns false if the amount of cards differentiate
            console.debug("ERROR: game state differentiates from the one of the leader because of the different amount of cards - resync the game of this player!")
            return false
          }
        }
      }
    }
    // returns true if all hands are synced
    return true
  }

  // the leader initializes all players and positions them at the borders of the game
  function initPlayers(){
      console.log("should init Players")
//    multiplayer.leaderCode(function () {
//      console.debug("Leader Init Players")
//      var clientPlayers = multiplayer.players
//      var playerInfo = []
//      for (var i = 0; i < clientPlayers.length; i++) {
//        playerTags.children[i].player = clientPlayers[i]
//        playerHands.children[i].player = clientPlayers[i]
//        playerInfo[i] = clientPlayers[i].userId
//      }
//    })
  }

  // find player by userId
  function getPlayer(userId){
    for (var i = 0; i < multiplayer.players.length; i++){
      console.debug("All UserIDs: " + multiplayer.players[i].userId + ", Looking for: " + userId)
      if (multiplayer.players[i].userId == userId){
        return multiplayer.players[i]
      }
    }
    console.debug("ERROR: could not find player with id", userId, "in the multiplayer.players list!")
    return undefined
  }

  // find hand by userId
  function getHand(userId){
    for (var i = 0; i < playerHands.children.length; i++){
      if (playerHands.children[i].player.userId == userId){
        return playerHands.children[i]
      }
    }
    console.debug("ERROR: could not find player with id", userId, "in the multiplayer.players list!")
    return undefined
  }

  // update tag by player userId
  function updateTag(userId, level, highscore, rank){
    for (var i = 0; i < playerTags.children.length; i++){
      if (playerHands.children[i].player.userId == userId){
        playerTags.children[i].level = level
        playerTags.children[i].highscore = highscore
        playerTags.children[i].rank = rank
      }
    }
  }

  // the other players position the players at the borders of the game field
  function syncPlayers(){
    console.debug("syncPlayers()")
    // it can happen that the multiplayer.players array is different than the one from the local user
    // possible reasons are, that a player meanwhile joined the game but this did not get forwarded to the room, or not forwarded to the leader yet

    // assign the players to the positions at the borders of the game field
    for (var j = 0; j < multiplayer.players.length; j++) {
      playerTags.children[j].player = multiplayer.players[j]
      playerHands.children[j].player = multiplayer.players[j]
    }
  }

  // the leader creates the deck and depot
  function initDeck(){
//    multiplayer.leaderCode(function () {
//      deck.createDeck()
//      depot.createDepot()
//    })
     deck.createDeck()
     console.log("Should init Deck....")
  }

  // the leader hands out the cards to the other players
  function initHands(){
//    multiplayer.leaderCode(function () {
//      for (var i = 0; i < playerHands.children.length; i++) {
//        // start the hand for each player
//        playerHands.children[i].startHand()
//      }
//    })
      console.log("Should init all Hand.")
  }

  // sync all hands according to the leader
  function syncHands(messageHands){
    console.debug("syncHands()")
    for (var i = 0; i < playerHands.children.length; i++){
      var currentUserId = playerHands.children[i].player.userId
      for (var j = 0; j < messageHands.length; j++){
        var messageUserId = messageHands[j].userId
        if (currentUserId == messageUserId){
          playerHands.children[i].syncHand(messageHands[j].handIds)
        }
      }
    }
  }

  // reset all tags and init the tag for the local player
  function initTags(){
    console.debug("initTags()")
//    for (var i = 0; i < playerTags.children.length; i++){
//      playerTags.children[i].initTag()
//      if (playerHands.children[i].player && playerHands.children[i].player.userId == multiplayer.localPlayer.userId){
//        playerTags.children[i].getPlayerData(true)
//      }
//    }
  }

  // draw the specified amount of cards
  function getCards(cards, userId){
    cardsDrawn = true

    // find the playerHand of the active player and pick up cards
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player.userId === userId){
        playerHands.children[i].pickUpCards(cards)
      }
    }
  }

  // change the current depot wild or wild4 card to the selected color and update the image
  function pickColor(pickedColor){
    if ((depot.current.variationType === "wild4" || depot.current.variationType === "wild")
        && depot.current.cardColor === "black"){
      depot.current.cardColor = pickedColor
      depot.current.updateCardImage()
    }
  }

  // check if the active player is close to winning (2 or less cards in the hand)
  function closeToWin(){
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player === multiplayer.activePlayer){
        playerHands.children[i].closeToWin()
      }
    }
  }

  // find the playerHand of the active player and mark all valid card options
  function markValid(){
    if (multiplayer.myTurn && !acted && !colorPicker.chosingColor){
      for (var i = 0; i < playerHands.children.length; i++) {
        if (playerHands.children[i].player === multiplayer.activePlayer){
          playerHands.children[i].markValid()
        }
      }
    } else {
      unmark()
    }
  }

  // unmark all valid card options of all players
  function unmark(){
    for (var i = 0; i < playerHands.children.length; i++) {
      playerHands.children[i].unmark()
    }
    // unmark the highlighted deck card
    deck.unmark()
  }

  // scale the playerHand of the active localPlayer
  function scaleHand(scale){
    if (!scale) scale = multiplayer.myTurn && !acted && !depot.skipped && !colorPicker.chosingColor ? 1.6 : 1.0
    for (var i = 0; i < playerHands.children.length; i++){
      if (playerHands.children[i].player && playerHands.children[i].player.userId == multiplayer.localPlayer.userId){
        playerHands.children[i].scaleHand(scale)
      }
    }
  }

  // end the turn of the active player
  function endTurn(){
    // unmark all highlighted valid card options
    unmark()
    // scale down the hand of the active local player
    scaleHand(1.0)

    var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
    // check if the active player has won the game and end it in that case
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player === multiplayer.activePlayer){
        if (playerHands.children[i].checkWin()){
          endGame()
          multiplayer.sendMessage(messageEndGame, {userId: userId})
          // make the player pick up two cards if he forgot to press the active onu button
        }else if (playerHands.children[i].missedOnu()){
          getCards(2, userId)
          multiplayer.sendMessage(messageMoveCardsHand, {cards: 2, userId: userId})
          if (multiplayer.myTurn) onuHint.visible = true
        }
      }
    }
    // continue if the game is still going
    if (!gameOver){
      console.debug("trigger new turn in endTurn, clockwise: " + depot.clockwise)
      if (multiplayer.amLeader){
        console.debug("Still Leader?")
        triggerNewTurn()
      } else {
        // send message to leader to trigger new turn
        multiplayer.sendMessage(messageTriggerTurn, userId)
      }
    }
  }

  function triggerNewTurn(userId){
    if (depot.clockwise){
      multiplayer.triggerNextTurn(userId)
    } else {
      multiplayer.triggerPreviousTurn(userId)
    }
  }

  // calculate the points for each player
  function calculatePoints(userId){
    // calculate the winner's score by adding all card values
    var score = 0
    for (var i = 0; i < playerHands.children.length; i++) {
      score += playerHands.children[i].points()
    }
    if (multiplayer.singlePlayer){
      score = Math.round(score/3)
    }

    // set the name of the winner
    if (userId == undefined) {
      // calculate the ranking of the other three players
      var tmpPlayers = [playerHands.children[0], playerHands.children[1], playerHands.children[2], playerHands.children[3]]
      var points = [score, 15, 10, 5]
      tmpPlayers.sort(function(a, b) {
        return a.hand.length - b.hand.length
      })

      var winnerHand = getHand(tmpPlayers[0].player.userId)
      if (winnerHand) gameScene.gameOver.winner = winnerHand.player

      for (var i = 0; i < tmpPlayers.length; i++){
        // get player by userId
        var tmpPlayer = getHand(tmpPlayers[i].player.userId)
        if (tmpPlayer) tmpPlayer.score = points[i]

        // check if two players had the same amount of cards
        if (i > 0){
          var prevPlayer = getHand(tmpPlayers[i-1].player.userId)
          if (prevPlayer && prevPlayer.hand.length == tmpPlayer.hand.length){
            tmpPlayer.score = prevPlayer.score
          }
        }
      }
    } else {
      // specific calculation for the "close round" desktop option
      // make the player who pressed the button the winner and simply order the other 3 players
      var tmpPlayers2 = []
      for (i = 0; i < playerHands.children.length; i++){
        if (playerHands.children[i].player.userId != userId){
          tmpPlayers2[tmpPlayers2.length] = playerHands.children[i]
        }
      }
      var points2 = [15, 10, 5]
      tmpPlayers2.sort(function(a, b) {
        return a.hand.length - b.hand.length
      })

      var winnerHand2 = getHand(userId)
      if (winnerHand2) gameScene.gameOver.winner = winnerHand2.player
      var winner = getHand(userId)
      if (winner) winner.score = score

      for (var j = 0; j < tmpPlayers2.length; j++){
        // get player by userId
        var tmpPlayer2 = getHand(tmpPlayers2[j].player.userId)
        if (tmpPlayer2) tmpPlayer2.score = points2[j]

        // check if two players had the same amount of cards
        if (j > 0){
          var prevPlayer2 = getHand(tmpPlayers2[j-1].player.userId)
          if (prevPlayer2 && prevPlayer2.hand.length == tmpPlayer2.hand.length){
            tmpPlayer2.score = prevPlayer2.score
          }
        }
      }
    }
  }

  // end the game and report the scores
  /*
    This is called by both the leader and the clients.
    Each user calculates and displays the points of all players. The local user reports his score and updates his level.
    If it differs from the previous level, the local user levelled up. In this case we display a message with the new level on the game over window.
    If he doesn't have a nickname, we ask him to chose one. Then we reset all timers and values.
    */
  function endGame(userId){
    // calculate the points of each player and set the name of the winner
    calculatePoints(userId)

    // show the gameOver message with the winner and score
    gameScene.gameOver.visible = true

    // add points to MultiplayerUser score of the winner
    var currentHand = getHand(multiplayer.localPlayer.userId)
    if (currentHand) gameNetwork.reportRelativeScore(currentHand.score)

    var currentTag
    for (var i = 0; i < playerTags.children.length; i++){
      if (playerTags.children[i].player.userId == multiplayer.localPlayer.userId){
        currentTag = playerTags.children[i]
      }
    }

    // calculate level with new points and check if there was a level up
    var oldLevel = currentTag.level
    currentTag.getPlayerData(false)
    if (oldLevel != currentTag.level){
      gameScene.gameOver.level = currentTag.level
      gameScene.gameOver.levelText.visible = true
    } else {
      gameScene.gameOver.levelText.visible = false
    }

    // show window with text input to switch username
    if (!multiplayer.singlePlayer && !gameNetwork.user.hasCustomNickName()) {
      gameScene.switchName.visible = true
    }

    // stop all timers and end the game
    scaleHand(1.0)
    gameOver = true
    onuButton.blinkAnimation.stop()
    aiTimeOut.stop()
    timer.running = false
    depot.effectTimer.stop()

    multiplayer.leaderCode(function () {
      restartGameTimer.start()
    })

//    ga.logEvent("System", "End Game", "singlePlayer", multiplayer.singlePlayer)
//    flurry.logEvent("System.EndGame", "singlePlayer", multiplayer.singlePlayer)
//    flurry.endTimedEvent("Game.TimeInGameSingleMatch", {"singlePlayer": multiplayer.singlePlayer})
  }

  function startNewGame(){
//    restartGameTimer.stop()
    // the true causes a gameStarted to be emitted
    gameLogic.initGame(true)
  }
}
