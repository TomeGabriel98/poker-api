require 'rails_helper'

RSpec.describe RoomsController, type: :controller do
  describe 'GET #index' do
    let(:rooms) { create_list(:room, 3) }

    before do
      allow(Room).to receive(:all).and_return(rooms)
    end

    it "successfully returns rooms list" do
      get :index

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
    end

    context "when an error is found" do
      before do
        allow(Room).to receive(:all).and_raise(StandardError)
      end

      it "returns an error" do
        get :index
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('An error has ocurred to list rooms')
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) { { room: { name: 'Room 1', max_players: 4 } } }
    let(:room) { build_stubbed(:room, valid_params[:room]) }

    before do
      allow(Room).to receive(:new).and_return(room)
      allow(room).to receive(:save!).and_return(true)
    end

    it 'returns created room' do
      post :create, params: valid_params

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(room.id)
      expect(json_response['name']).to eq('Room 1')
      expect(json_response['max_players']).to eq(4)
    end

    context "when record is invalid" do
      before do
        allow(Room).to receive(:new).and_raise(ActiveRecord::RecordInvalid)
      end

      it "returns an error" do
        post :create, params: valid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('The data informed to save room is invalid')
      end
    end

    context "when generic error is returned" do
      before do
        allow(Room).to receive(:new).and_raise(StandardError)
      end

      it "returns an error" do
        post :create, params: valid_params
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('An error has ocurred to save room')
      end
    end
  end

  describe 'POST #join' do
    let(:room) { create(:room) }
    let(:player) { create(:player) }

    before do
      allow(Room).to receive(:find).and_return(room)
      allow(Player).to receive(:find).and_return(player)
      allow_any_instance_of(Room).to receive(:join_room).and_return(room)
    end

    it 'player joins the room' do
      post :join, params: { id: room.id, player_id: player.id }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq("Player joined successfully")
    end

    context "when record is not found" do
      before do
        allow(Room).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns an error" do
        post :join, params: { id: room.id, player_id: player.id }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Could not found: ')
      end
    end

    context "when generic error is returned" do
      before do
        allow(Room).to receive(:find).and_raise(StandardError)
      end

      it "returns an error" do
        post :join, params: { id: room.id, player_id: player.id }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('An error has ocurred to join the room')
      end
    end
  end

  describe 'POST #leave' do
    let(:room) { create(:room) }
    let(:player) { create(:player) }

    before do
      allow(Room).to receive(:find).and_return(room)
      allow_any_instance_of(Room).to receive(:leave_room).and_return(room)
    end

    it 'player leaves the room' do
      post :leave, params: { id: room.id, player_id: player.id }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq("Player left successfully")
    end

    context "when record is not found" do
      before do
        allow(Room).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns an error" do
        post :leave, params: { id: room.id, player_id: player.id }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Could not found: ')
      end
    end

    context "when generic error is returned" do
      before do
        allow(Room).to receive(:find).and_raise(StandardError)
      end

      it "returns an error" do
        post :leave, params: { id: room.id, player_id: player.id }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('An error has ocurred to left the room')
      end
    end
  end

  describe 'POST #start' do
    let(:room) { create(:room) }
    let(:game) { create(:game) }

    before do
      allow(Room).to receive(:find).and_return(room)
      allow(Game).to receive(:find).and_return(game)
      allow_any_instance_of(Room).to receive(:start_game!).and_return(room)
    end

    it 'returns success response with initial game state' do
      post :start, params: { id: room.id }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('Game started')
      expect(json_response['initial_state']['pot']).to eq(0)
      expect(json_response['initial_state']['community_cards']).to eq([])
    end

    context "when record is not found" do
      before do
        allow(Room).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns an error" do
        post :start, params: { id: room.id }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Could not found: ')
      end
    end

    context "when not authorized action is performed" do
      before do
        allow(Room).to receive(:find).and_raise(Errors::UnauthorizedGameOperationError)
      end

      it "returns an error" do
        post :start, params: { id: room.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
      end
    end

    context "when generic error is returned" do
      before do
        allow(Room).to receive(:find).and_raise(StandardError)
      end

      it "returns an error" do
        post :start, params: { id: room.id }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('An error has ocurred to left the room')
      end
    end
  end

  describe 'POST #action' do
    let(:room) { create(:room) }
    let(:player) { create(:player) }
    let(:game) { create(:game) }

    before do
      allow(Room).to receive(:find).and_return(room)
      allow(Game).to receive(:find_by).and_return(game)
      allow_any_instance_of(Room).to receive(:process_action!).and_return(room)
    end

    it 'performs a player action' do
      post :action, params: { id: room.id, player_id: player.id, player_action: 'raise', amount: 2 }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('Action performed succesfully')
      expect(json_response['game_state']['current_turn']).to eq(game.current_turn)
      expect(json_response['game_state']['pot']).to eq(game.pot)
    end

    context "when record is not found" do
      before do
        allow(Room).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns an error" do
        post :action, params: { id: room.id, player_id: player.id, player_action: 'raise', amount: 2 }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Could not found: ')
      end
    end

    context "when not authorized action is performed" do
      before do
        allow(Room).to receive(:find).and_raise(Errors::UnauthorizedGameOperationError)
      end

      it "returns an error" do
        post :action, params: { id: room.id, player_id: player.id, player_action: 'raise', amount: 2 }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
      end
    end

    context "when generic error is returned" do
      before do
        allow(Room).to receive(:find).and_raise(StandardError)
      end

      it "returns an error" do
        post :action, params: { id: room.id, player_id: player.id, player_action: 'raise', amount: 2 }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('An error has ocurred to perform the action')
      end
    end
  end

  describe 'POST #next_phase' do
    let(:room) { create(:room) }
    let(:game) { create(:game) }

    before do
      allow(Room).to receive(:find).and_return(room)
      allow(Game).to receive(:find_by).and_return(game)
      allow_any_instance_of(Room).to receive(:next_phase!).and_return(room)
    end

    it 'procceeds to next phase' do
      post :next_phase, params: { id: room.id }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['phase']).to eq(game.current_phase)
      expect(json_response['community_cards']).to eq(game.community_cards)
    end

    context "when record is not found" do
      before do
        allow(Room).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns an error" do
        post :next_phase, params: { id: room.id }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Could not found: ')
      end
    end

    context "when not authorized action is performed" do
      before do
        allow(Room).to receive(:find).and_raise(Errors::UnauthorizedGameOperationError)
      end

      it "returns an error" do
        post :next_phase, params: { id: room.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
      end
    end

    context "when generic error is returned" do
      before do
        allow(Room).to receive(:find).and_raise(StandardError)
      end

      it "returns an error" do
        post :next_phase, params: { id: room.id }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('An error has ocurred to advance phase')
      end
    end
  end

  describe 'POST #end' do
    let(:room) { create(:room) }
    let(:game) { create(:game, :with_winner) }

    before do
      allow(Room).to receive(:find).and_return(room)
      allow(Game).to receive(:find_by).and_return(game)
      allow_any_instance_of(Room).to receive(:showdown!).and_return(room)
    end

    it 'finishes the game' do
      post :end, params: { id: room.id }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['winner']['player_id']).to eq(game.winner_player["id"])
      expect(json_response['winner']['hand']).to eq(game.winner_hand)
      expect(json_response['pot']).to eq(game.pot)
    end

    context "when record is not found" do
      before do
        allow(Room).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns an error" do
        post :end, params: { id: room.id }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Could not found: ')
      end
    end

    context "when not authorized action is performed" do
      before do
        allow(Room).to receive(:find).and_raise(Errors::UnauthorizedGameOperationError)
      end

      it "returns an error" do
        post :end, params: { id: room.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
      end
    end

    context "when generic error is returned" do
      before do
        allow(Room).to receive(:find).and_raise(StandardError)
      end

      it "returns an error" do
        post :end, params: { id: room.id }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('An error has ocurred to finish the game')
      end
    end
  end
end
