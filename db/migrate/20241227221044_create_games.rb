class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.integer :room_id
      t.integer :player_ids, array: true, default: []
      t.string :current_phase
      t.integer :current_turn
      t.jsonb :deck, default: []
      t.jsonb :community_cards, default: []
      t.integer :pot
      t.jsonb :winner_player
      t.string :winner_hand

      t.timestamps
    end
  end
end
