class CreateCards < ActiveRecord::Migration[8.0]
  def change
    create_table :cards do |t|
      t.string :value, null: false
      t.string :suit, null: false
      t.string :identifier, null: false

      t.timestamps
    end
  end
end
