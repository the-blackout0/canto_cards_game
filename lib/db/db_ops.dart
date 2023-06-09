import 'package:canto_cards_game/game/cards/card_model.dart';
import 'package:canto_cards_game/game/cards/player_card.dart';
import 'package:canto_cards_game/game/game_details_model.dart';
import 'package:canto_cards_game/game/game_model.dart';
import 'package:canto_cards_game/game/round_details_model.dart';
import 'package:canto_cards_game/player/player_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DbOps {
  final supabase = Supabase.instance.client;

  Future<List<Game>> getNewGames() async {
    final List<dynamic> data = await supabase.from('games').select('*').match({'status': 'new'});
    if (data.isEmpty) {
      // handle empty data
      return [];
    }
    List<Game> games = data.map((e) => Game.fromJson(e)).toList();
    return games;
  }

  Future<Game> insertGame(String name, int hostId) async {
    final List<Map<String, dynamic>> data = await supabase.from('games').insert([
      {'name': name, 'hostId': hostId},
    ]).select();
    return Game.fromJson(data.first);
  }

  Future<Game> updateGame(Game game) async {
    final List<Map<String, dynamic>> data = await supabase.from('games').update(game.toJson()).eq('id', game.id).select();

    return Game.fromJson(data.first);
  }

  Future<Player> getPlayer(int id) async {
    final List<dynamic> data = await supabase.from('players').select('*').match({'id': id});
    if (data.isEmpty) {
      // handle empty data
      // return null;
    }
    Player player = Player.fromJson(data.first);
    return player;
  }

  Future<GameDetails> insertGameDetails(GameDetails gameDetails) async {
    final List<Map<String, dynamic>> data = await supabase
        .from('game_details')
        .insert(
          gameDetails.toJson(),
        )
        .select();
    return GameDetails.fromJson(data.first);
  }

  Future<GameDetails> updateGameDetails(GameDetails gameDetails) async {
    final List<Map<String, dynamic>> data = await supabase.from('game_details').update(gameDetails.toJson()).eq('id', gameDetails.id).select();

    return GameDetails.fromJson(data.first);
  }

  Future<Game> updateGameStatus(Game game) async {
    final List<Map<String, dynamic>> data = await supabase.from('games').update({'status': game.status}).eq('id', game.id).select();

    return Game.fromJson(data.first);
  }

  Future<GameDetails> getGameDetails(int gameDetailsId) async {
    print("getGameDetails: $gameDetailsId");
    final List<dynamic> data = await supabase.from('game_details').select('*').match(
      {'id': gameDetailsId},
    );
    if (data.isEmpty) {
      // handle empty data
      // return null;
    }
    return GameDetails.fromJson(data.first);
  }

  Future<GameDetails> getGameDetailsBy(int gameId) async {
    print("Game Details by Game id: $gameId");
    final List<dynamic> data = await supabase.from('game_details').select('*').match(
      {'gameId': gameId},
    );
    if (data.isEmpty) {
      // handle empty data
      // return null;
    }
    return GameDetails.fromJson(data.first);
  }

  Future<List<int>?> getUserDeckIds(int userId) async {
    final List<dynamic> data = await supabase.from('deck').select('id').match({'userId': userId});
    return data.map((e) => e["id"]).toList().cast<int>();
  }

  Future<CardModel> getCardById(int id) async {
    final List<dynamic> data = await supabase.from('cards').select('*').match({'id': id});
    return CardModel.fromJson(data.first);
  }

  Future<List<PlayerCard>> getUserCardModel(int userId) async {
    final List<dynamic> data = await supabase.from('deck').select('id, cards(*)').match({'userId': userId});
    return data.map((playerCard) => PlayerCard.fromJson(playerCard)).toList();
  }

  Future<List<PlayerCard>> getPlayedCards(List<int> cardIds) async {
    final List<dynamic> data = await supabase.from('deck').select('id, cards(*)').in_('id', cardIds);
    return data.map((playerCard) => PlayerCard.fromJson(playerCard)).toList();
  }

  Future<RoundDetails> insertRoundDetails(RoundDetails roundDetails) async {
    final List<Map<String, dynamic>> data = await supabase
        .from('round_details')
        .insert(
          roundDetails.toJson(),
        )
        .select();
    return RoundDetails.fromJson(data.first);
  }

  Future<RoundDetails> getRoundDetailsBy(int gameId) async {
    final List<dynamic> data = await supabase.from('round_details').select('*').match(
      {'gameId': gameId},
    );

    return RoundDetails.fromJson(data.first);
  }

  Future<RoundDetails> updateRoundDetailsHostReady(RoundDetails rd) async {
    final List<Map<String, dynamic>> data = await supabase.from('round_details').update({'hostReady': rd.hostReady}).eq('id', rd.id).select();
    return RoundDetails.fromJson(data.first);
  }

  Future<RoundDetails> updateRoundDetailsJoinerReady(RoundDetails rd) async {
    final List<Map<String, dynamic>> data = await supabase.from('round_details').update({'joinerReady': rd.joinerReady}).eq('id', rd.id).select();
    return RoundDetails.fromJson(data.first);
  }

  Future<RoundDetails> updateRoundDetailsHostMoves(RoundDetails rd) async {
    final List<Map<String, dynamic>> data = await supabase.from('round_details').update({'hostMoves': rd.hostMoves}).eq('id', rd.id).select();
    return RoundDetails.fromJson(data.first);
  }

  Future<RoundDetails> updateRoundDetailsJoinerMoves(RoundDetails rd) async {
    final List<Map<String, dynamic>> data = await supabase.from('round_details').update({'joinerMoves': rd.joinerMoves}).eq('id', rd.id).select();
    return RoundDetails.fromJson(data.first);
  }
}
