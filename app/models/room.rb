class Room < ApplicationRecord
	def join_room(player)
		current_players << {
      id: player.id,
      name: player.name,
      chips: player.chips,
      current_bet: player.current_bet,
      hand: player.hand
    }
    save!

		broadcast_to_clients(type: "updatePlayers",
      players: current_players
    )
	end

	def leave_room(player_id)
    current_players.reject! { |p| p["id"] == player_id }
    save!

		broadcast_to_clients(type: "updatePlayers",
      players: current_players
    )
  end

	def start_game!(game)
		game.room_id = id
		if active_game
			raise Errors::UnauthorizedGameOperationError.new("There is already a game for this room", {game: game})
		end

		self.active_game = true
		self.deck = game.build_deck.shuffle

		current_players.each do |player|
			player[:hand] = [deck.pop, deck.pop]
		end

		self.current_player_turn = current_players.first["id"]

		update_data(game)
		save!

		broadcast_to_clients(type: 'gameStarted',
			players: current_players,
			community_cards: game.community_cards,
			pot: game.pot,
			current_turn: current_player_turn
		)
	end

	def process_action!(game, player_id, action, amount = 0)
		if player_id != current_player_turn
			raise Errors::UnauthorizedGameOperationError.new("It's not your turn", {current_player_id: current_player_turn})
		end

		if !active_game
			raise Errors::UnauthorizedGameOperationError.new("This room has not an active game", {room_id: id})
		end

		player = current_players.find { |p| p["id"] == player_id }

		case action
		when "check"
			player["finished"] = true
		when "call"
			highest_bet = current_players.map { |p| p["current_bet"] }.max
			difference = highest_bet - player["current_bet"]

			if player["chips"] < difference
				raise Errors::UnauthorizedGameOperationError.new("You do not have enough chips", {remaining_chips: player["chips"]})
			end

			player["chips"] -= difference
			player["current_bet"] += difference
			game.pot += difference
			player["finished"] = true
		when "raise"
			if player["chips"] < amount
				raise Errors::UnauthorizedGameOperationError.new("You do not have enough chips", {remaining_chips: player["chips"]})
			end
			
			player["chips"] -= amount
			player["current_bet"] += amount
			game.pot += amount
			reset_all_players_status
			player["finished"] = true
		when "fold"
			player["folded"] = true
			if get_active_players(current_players).size == 1
				showdown!(game)
				return
			end
		end

		next_turn!(game)
		update_data(game)
		save!

		if all_players_finished?
			next_phase!(game)
		end

		broadcast_to_clients(
			type: 'playerAction',
			pot: game.pot,
			players: current_players,
			current_turn: current_player_turn,
			current_phase: game.current_phase
		)
	end

	def next_phase!(game)
		case game.current_phase
		when 'pre-flop'
			game.current_phase = 'flop'
			game.community_cards = deck.pop(3)
		when 'flop'
			game.current_phase = 'turn'
			game.community_cards << deck.pop
		when 'turn'
			game.current_phase = 'river'
			game.community_cards << deck.pop
		when 'river'
			showdown!(game)
			return
		else
			raise Errors::UnauthorizedGameOperationError.new("The current phase are not mapped in the game.", {current_phase: game.current_phase})
		end

		reset_all_players_status
		update_data(game)
		save!

		broadcast_to_clients(
			type: 'phaseChanged',
			community_cards: game.community_cards,
			current_phase: game.current_phase,
			current_turn: current_player_turn
		)
	end

	def showdown!(game)
		community_cards = game.community_cards
		player_hands = get_active_players(current_players).map do |player|
			{
				id: player["id"],
				name: player["name"],
				hand: player["hand"] + community_cards,
				chips: player["chips"],
				player: player
			}
		end

		winner = determine_winner(player_hands)

		if !winner
			raise Errors::UnauthorizedGameOperationError.new("A winner could not be determined", {game: game})
		end

		game.winner_player = winner[:winning_player]
		game.winner_hand = winner[:winning_hand]
		game.community_cards = []
		game.pot = 0
		self.active_game = false
	
		update_data(game)
		save!

		broadcast_to_clients(
			type: "showdown",
			winner: game.winner_player,
			hand: game.winner_hand
		)
	end

	private

	def get_active_players(players)
		players.reject { |p| p["folded"] }
	end

	def update_data(data)
		ActiveRecord::Base.transaction do
			data.save!
		end
	end

	def determine_winner(player_hands)
		ranked_players = player_hands.sort_by do |player|
			rank_hand(player[:hand])[:rank]
		end.reverse

		winner = ranked_players.first

		{
			winning_player: winner,
			winning_hand: rank_hand(winner[:hand])[:hand]
		}
	end

	def rank_hand(cards)
		PokerHandEvaluator.new(cards).rank
	end

	def all_players_finished?
		active_players = current_players.reject { |p| p["folded"] }
		
		active_players.all? do |player|
			player["finished"] == true
		end
	end

	def reset_all_players_status
		current_players.all? do |player|
			player["finished"] = false
		end
	end

	def next_turn!(game)
		active_players = get_active_players(current_players)
		current_index = active_players.find_index { |p| p["id"] == current_player_turn }

		self.current_player_turn = if current_index.nil? || current_index + 1 >= active_players.size
			active_players.first["id"]
		else
			active_players[current_index + 1]["id"]
		end
		
		game.current_turn += 1
	end

	def broadcast_to_clients(data)
    ActionCable.server.broadcast("room_#{id}", data)
  end
end
