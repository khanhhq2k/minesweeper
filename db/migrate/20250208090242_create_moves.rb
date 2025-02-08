class CreateMoves < ActiveRecord::Migration[8.0]
  def change
    create_table :moves do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :row
      t.integer :col
      t.string :action

      t.timestamps
    end
  end
end
