require 'rails_helper'

RSpec.describe Room, type: :model do
  let(:room) { create(:room) }
  let(:player1) { create(:player) }
  let(:player2) { create(:player) }
  let(:player3) { create(:player) }
  let(:game) { create(:game) }

  before do
    allow(ActionCable.server).to receive(:broadcast)
  end

  describe "#join_room" do
    it "adds a player to the room and broadcasts to clients" do
      expect {
        room.join_room(player1)
      }.to change { room.current_players.size }.by(1)

      expect(room.current_players.last["name"]).to eq(player1.name)
      expect(ActionCable.server).to have_received(:broadcast).with(
        "room_#{room.id}",
        hash_including(type: "updatePlayers", players: room.current_players)
      )
    end
  end

  describe "#leave_room" do
    before { room.join_room(player1) }

    it "removes the player from the room and broadcasts to clients" do
      expect {
        room.leave_room(player1.id)
      }.to change { room.current_players.size }.by(-1)

      expect(ActionCable.server).to have_received(:broadcast).with(
        "room_#{room.id}",
        hash_including(type: "updatePlayers", players: room.current_players)
      ).exactly(2).times
    end
  end

  describe "#start_game!" do
    context "when no active game exists" do
      it "initializes a new game and assigns hands to players" do
        room.join_room(player1)
        room.join_room(player2)

        expect {
          room.start_game!(game)
        }.to change { room.active_game }.from(false).to(true)

        expect(room.current_players.first["hand"].size).to eq(2)
        expect(room.current_player_turn).to eq(player1.id)

        expect(ActionCable.server).to have_received(:broadcast).with(
          "room_#{room.id}",
          hash_including(type: 'gameStarted')
        )
      end
    end

    context "when an active game already exists" do
      before { room.update(active_game: true) }

      it "raises an error" do
        expect {
          room.start_game!(game)
        }.to raise_error(Errors::UnauthorizedGameOperationError)
      end
    end
  end

  describe "#process_action!" do
    before do
      room.join_room(player1)
      room.join_room(player2)
      room.start_game!(game)
    end

    it "raises a player's bet and advances the turn" do
      expect {
        room.process_action!(game, player1.id, "raise", 2)
      }.to change { game.pot }.by(2)

      expect(room.current_player_turn).to eq(player2.id)
      expect(ActionCable.server).to have_received(:broadcast).with(
        "room_#{room.id}",
        hash_including(type: 'playerAction')
      )
    end

    context "on second player's turn" do
      before do
        room.leave_room(player1)
        player1.update(current_bet: 2)
        room.join_room(player1)
        room.update(current_player_turn: player2.id)
      end

      it "calls the first player's bet and advances the turn" do
        expect {
          room.process_action!(game, player2.id, "call", 2)
        }.to change { game.pot }.by(2)
  
        expect(room.current_player_turn).to eq(player1.id)
        expect(ActionCable.server).to have_received(:broadcast).with(
          "room_#{room.id}",
          hash_including(type: 'playerAction')
        )
      end
    end

    context "when there's three players in game" do
      before {room.join_room(player3) }

      it "fold one player's hand and advances the turn" do
        expect {
          room.process_action!(game, player1.id, "fold")
        }.to change { game.pot }.by(0)
  
        expect(room.current_player_turn).to eq(player2.id)
        expect(ActionCable.server).to have_received(:broadcast).with(
          "room_#{room.id}",
          hash_including(type: 'playerAction')
        )
      end
    end

    it "raises an error if it's not the player's turn" do
      expect {
        room.process_action!(game, player2.id, "call")
      }.to raise_error(Errors::UnauthorizedGameOperationError)
    end
  end

  describe "#next_phase!" do
    before do
      room.join_room(player1)
      room.join_room(player2)
      room.start_game!(game)
    end

    context "when current phase is pre flop" do
      it "progresses the game to the flop phase" do
        expect {
          room.next_phase!(game)
        }.to change { game.current_phase }.from("pre-flop").to("flop")
  
        expect(ActionCable.server).to have_received(:broadcast).with(
          "room_#{room.id}",
          hash_including(type: "phaseChanged")
        )
      end
    end

    context "when current phase is flop" do
      before { game.update(current_phase: 'flop') }

      it "progresses the game to the turn phase" do
        expect {
          room.next_phase!(game)
        }.to change { game.current_phase }.from("flop").to("turn")
  
        expect(ActionCable.server).to have_received(:broadcast).with(
          "room_#{room.id}",
          hash_including(type: "phaseChanged")
        )
      end
    end

    context "when current phase is turn" do
      before { game.update(current_phase: 'turn') }

      it "progresses the game to the river phase" do
        expect {
          room.next_phase!(game)
        }.to change { game.current_phase }.from("turn").to("river")
  
        expect(ActionCable.server).to have_received(:broadcast).with(
          "room_#{room.id}",
          hash_including(type: "phaseChanged")
        )
      end
    end

    context "when current phase is not supported" do
      before { game.update(current_phase: 'not supported') }

      it "raises an error" do
        expect {
        room.next_phase!(game)
      }.to raise_error(Errors::UnauthorizedGameOperationError)
      end
    end
  end

  describe "#showdown!" do
    before do
      room.join_room(player1)
      room.join_room(player2)
      room.start_game!(game)
    end

    it "determines the winner and broadcasts to clients" do
      allow(room).to receive(:determine_winner).and_return({
        winning_player: player1,
        winning_hand: "pair"
      })

      room.showdown!(game)
      expect(game.winner_player["id"]).to eq(player1["id"])
      expect(game.winner_hand).to eq("pair")

      expect(ActionCable.server).to have_received(:broadcast).with(
        "room_#{room.id}",
        hash_including(type: "showdown")
      )
    end

    it "raises an error if no winner can be determined" do
      allow(room).to receive(:determine_winner).and_return(nil)

      expect {
        room.showdown!(game)
      }.to raise_error(Errors::UnauthorizedGameOperationError)
    end
  end
end
