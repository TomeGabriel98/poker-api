class RoomsController < ApplicationController
	def index
		begin
			rooms = Room.all.as_json(except: [:created_at, :updated_at])

			render json: rooms
		rescue StandardError => e
			render json: { message: 'An error has ocurred to list rooms', error: e }, status: :internal_server_error
		end
	end

	def create
		begin
				@room = Room.new(room_params)
				@room.save!

				render json: { id: @room.id, name: @room.name, max_players: @room.max_players, current_players: @room.current_players }
		rescue ActiveRecord::RecordInvalid => e
				render json: { message: "The data informed to save room is invalid", errors: e }, status: :unprocessable_entity
		rescue StandardError => e
				render json: { message: 'An error has ocurred to save room', error: e }, status: :internal_server_error
		end
	end

	def join
		begin
			player_id = params.require(:player_id)
			@room = Room.find(params[:id])
			player = Player.find(player_id)

			@room.join_room(player)

			render json: { "message": "Player joined successfully" }
		rescue ActionController::ParameterMissing => e
			render json: { message: "A required param to join the room is missing: ", errors: e }, status: :unprocessable_entity
		rescue ActiveRecord::RecordNotFound => e
			render json: { message: 'Could not found: ', error: e }, status: :not_found
		rescue StandardError => e
			render json: { message: 'An error has ocurred to join the room', error: e }, status: :internal_server_error
		end
	end
	
	def leave
		begin
			player_id = params.require(:player_id)
			@room = Room.find(params[:id])
			
			@room.leave_room(player_id)

			render json: { "message": "Player left successfully" }
		rescue ActionController::ParameterMissing => e
			render json: { message: "A required param to join the room is missing: ", errors: e }, status: :unprocessable_entity
		rescue ActiveRecord::RecordNotFound => e
			render json: { message: 'Could not found: ', error: e }, status: :not_found
		rescue StandardError => e
			render json: { message: 'An error has ocurred to left the room', error: e }, status: :internal_server_error
		end
	end

	def start
		begin
			room_id = params[:id]
			@room = Room.find(room_id)
			@game = Game.new
			@room.start_game!(@game)

			render json: {
				message: "Game started",
				initial_state: {
					players: @room.current_players,
					community_cards: [],
					pot: 0
				}
			}
		rescue ActionController::ParameterMissing => e
			render json: { message: "A required param to join the room is missing: ", errors: e }, status: :unprocessable_entity
		rescue ActiveRecord::RecordNotFound => e
			render json: { message: 'Could not found: ', error: e }, status: :not_found
		rescue Errors::UnauthorizedGameOperationError => e
			Rails.logger.error("Erro capturado: #{e.message}, Detalhes: #{e.details}")
    	render json: { error: e.message, details: e.details }, status: :unprocessable_entity
		rescue StandardError => e
			render json: { message: 'An error has ocurred to left the room', error: e }, status: :internal_server_error
		end
	end

	def action
		begin
			room_id = params[:id]
			player_id = params.require(:player_id)
			player_action = params.require(:player_action)
			amount = params.require(:amount)

			@room = Room.find(room_id)
			@game = Game.find_by(room_id: room_id)

			@room.process_action!(@game, player_id, player_action, amount)

			render json: { 
				message: "Action performed succesfully",
				game_state: {
					current_turn: @game.current_turn,
					pot: @game.pot
				}
			}
		rescue ActionController::ParameterMissing => e
			render json: { message: "A required param to join the room is missing: ", errors: e }, status: :unprocessable_entity
		rescue ActiveRecord::RecordNotFound => e
			render json: { message: 'Could not found: ', error: e }, status: :not_found
		rescue Errors::UnauthorizedGameOperationError => e
			Rails.logger.error("Erro capturado: #{e.message}, Detalhes: #{e.details}")
    	render json: { error: e.message, details: e.details }, status: :unprocessable_entity
		rescue StandardError => e
			render json: { message: 'An error has ocurred to perform the action', error: e }, status: :internal_server_error
		end
	end

	def next_phase
		begin
			room_id = params[:id]
			@room = Room.find(room_id)
			@game = Game.find_by(room_id: room_id)

			@room.next_phase!(@game)

			render json: { 
				phase: @game.current_phase,
				community_cards: @game.community_cards
			}
		rescue ActionController::ParameterMissing => e
			render json: { message: "A required param to join the room is missing: ", errors: e }, status: :unprocessable_entity
		rescue ActiveRecord::RecordNotFound => e
			render json: { message: 'Could not found: ', error: e }, status: :not_found
		rescue Errors::UnauthorizedGameOperationError => e
			Rails.logger.error("Erro capturado: #{e.message}, Detalhes: #{e.details}")
    	render json: { error: e.message, details: e.details }, status: :unprocessable_entity
		rescue StandardError => e
			render json: { message: 'An error has ocurred to advance phase', error: e }, status: :internal_server_error
		end
	end

	def end
		begin
			room_id = params[:id]
			@room = Room.find(room_id)
			@game = Game.find_by(room_id: room_id)

			@room.showdown!(@game)

			render json: {
				winner: {
					player_id: @game.winner_player["id"],
					hand: @game.winner_hand
				},
				pot: @game.pot
			}
		rescue ActionController::ParameterMissing => e
			render json: { message: "A required param to join the room is missing: ", errors: e }, status: :unprocessable_entity
		rescue ActiveRecord::RecordNotFound => e
			render json: { message: 'Could not found: ', error: e }, status: :not_found
		rescue Errors::UnauthorizedGameOperationError => e
			Rails.logger.error("Erro capturado: #{e.message}, Detalhes: #{e.details}")
    	render json: { error: e.message, details: e.details }, status: :unprocessable_entity
		rescue StandardError => e
			render json: { message: 'An error has ocurred to finish the game', error: e }, status: :internal_server_error
		end
	end

	private

	def room_params
		params.require(:room).permit(:name, :max_players)
	end
end
