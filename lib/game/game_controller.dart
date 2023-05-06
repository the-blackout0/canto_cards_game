import 'package:canto_cards_game/db/db_ops.dart';
import 'package:canto_cards_game/game/cards/cards.dart';
import 'package:canto_cards_game/game/cards/player_card.dart';
import 'package:canto_cards_game/game/game_details_model.dart';
import 'package:canto_cards_game/game/game_model.dart';
import 'package:canto_cards_game/player/player_model.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameController extends GetxController {
  Rx<Game> game = Game.empty().obs;

  Rx<Player> host = Player.empty().obs;
  Rx<Player> joiner = Player.empty().obs;

  int userId = Get.arguments["userId"]!;

  Rx<GameDetails> gameDetails = GameDetails.empty().obs;
  DbOps db = Get.find<DbOps>();
  CardsService cs = Get.find<CardsService>();

  RxList<PlayerCard> playerDeck = <PlayerCard>[].obs;
  RxList<PlayerCard> opponentDeck = <PlayerCard>[].obs;
  RxList<PlayerCard> playerPlayedCards = <PlayerCard>[].obs;
  RxList<PlayerCard> opponentPlayedCards = <PlayerCard>[].obs;

  var channel;

  @override
  Future<void> onInit() async {
    super.onInit();
    game.value = Get.arguments['game'] ?? game.value;
    host.value = Get.arguments['host'] ?? host.value;
    joiner.value = Get.arguments['joiner'] ?? joiner.value;

    playerDeck.value = isHost() ? await cs.getCards(host.value.id!) : await cs.getCards(joiner.value.id!);
    opponentDeck.value = isHost() ? await cs.getCards(joiner.value.id!) : await cs.getCards(host.value.id!);

    gameDetails.value = await db.getGameDetailsBy(game.value.id);

    opponentPlayedCards.value =
        isHost() ? await cs.getPlayedCards(gameDetails.value.joinerPlayedCards!) : await cs.getPlayedCards(gameDetails.value.hostPlayedCards!);

    playerPlayedCards.value =
        isHost() ? await cs.getPlayedCards(gameDetails.value.hostPlayedCards!) : await cs.getPlayedCards(gameDetails.value.joinerPlayedCards!);

    channel = db.supabase.channel('public:game_details:id=eq.${gameDetails.value.id}').on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'game_details',
          filter: 'id=eq.${gameDetails.value.id}',
        ), (payload, [ref]) async {
      print('Game Play Update: ${payload.toString()}');
      GameDetails gd = GameDetails.fromJson(payload["new"]);
      gameDetails.value = gd;

      if (isHost()) {
        opponentPlayedCards.value = await cs.getPlayedCards(gameDetails.value.joinerPlayedCards!);
      } else {
        opponentPlayedCards.value = await cs.getPlayedCards(gameDetails.value.hostPlayedCards!);
      }
    });
    channel.subscribe();
  }

  void playCard(PlayerCard card) {
    playerPlayedCards.add(card);
    playerDeck.removeWhere((cardToRemove) => cardToRemove.id == card.id);
  }

  bool isHost() {
    return game.value.hostId == userId;
  }

  String getOpponentName() {
    return isHost() ? joiner.value.name : host.value.name;
  }

  String getPlayerName() {
    return isHost() ? host.value.name : joiner.value.name;
  }

  @override
  Future<void> onClose() async {
    super.onClose();
    host.close();
    joiner.close();
    gameDetails.close();
    playerDeck.close();
    opponentDeck.close();
    playerPlayedCards.close();
    opponentPlayedCards.close();
    await db.supabase.removeChannel(channel);
  }

  Future<void> playRound() async {
    if (isHost()) {
      gameDetails.value.hostPlayedCards = cs.getIdFromCards(playerPlayedCards);
      gameDetails.value.hostDeck = cs.getIdFromCards(playerDeck);
    } else {
      gameDetails.value.joinerPlayedCards = cs.getIdFromCards(playerPlayedCards);
      gameDetails.value.joinerDeck = cs.getIdFromCards(playerDeck);
    }
    gameDetails.value = await db.updateGameDetails(gameDetails.value);
  }

  String getOpponentImage() {
    return isHost() ? 'images/avatars/cypher.gif' : 'images/avatars/zenith.gif';
  }

  String getPlayerImage() {
    return isHost() ? 'images/avatars/zenith.gif' : 'images/avatars/cypher.gif';
  }

  bool isPlayBtnVisible(PlayerCard card) {
    return !(playerPlayedCards.contains(card) || opponentPlayedCards.contains(card));
  }
}
