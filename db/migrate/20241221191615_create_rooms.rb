class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :name
      t.integer :max_players
      t.boolean :active_game, default: false
      t.jsonb :current_players, default: []
      t.jsonb :deck, default: []
      t.integer :current_player_turn

      t.timestamps
    end
  end
end
