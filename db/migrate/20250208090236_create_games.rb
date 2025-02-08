class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.integer :width, null: false
      t.integer :height, null: false
      t.integer :mines, null: false
      t.json :board, null: false
      t.json :revealed, null: false
      t.json :flags, null: false
      t.boolean :game_over, default: false

      t.timestamps
    end
    add_index :games, [:email, :name]

  end
end
