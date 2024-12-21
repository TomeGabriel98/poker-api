class PlayersController < ApplicationController
		def create
			begin
				@player = Player.new(player_params)
				@player.chips = 1000
				
				@player.save!

				render json: { id: @player.id, name: @player.name, chips: @player.chips }
			rescue ActiveRecord::RecordInvalid => e
				render json: { message: "Erro", errors: e }, status: :unprocessable_entity
			rescue StandardError => e
				render json: { message: 'Ocorreu um erro do capeta', error: e }, status: :internal_server_error
			end
		end

		def destroy
			begin
				@player = Player.find(params[:id])
				@player.destroy!

				render json: { "message": "Player deleted successfully" }
			rescue ActiveRecord::RecordNotFound => e
				render json: { message: 'Player not found', error: e }, status: :not_found
			rescue StandardError => e
				render json: { message: 'Ocorreu um erro do capeta', error: e }, status: :internal_server_error
			end
		end
	
		private
	
		def player_params
			params.require(:player).permit(:name)
		end
end
