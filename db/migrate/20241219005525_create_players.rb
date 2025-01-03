class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :name
      t.integer :chips
      t.integer :current_bet, default: 0
      t.string :hand, array: true, default: []

      t.timestamps
    end
  end
end
