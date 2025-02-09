class Move < ApplicationRecord
  belongs_to :game
  
  validates :row, :col, :action, presence: true
  validates :action, inclusion: { in: ['reveal', 'flag'] }
  
  after_create :update_game_stats
  
  private
  
  def update_game_stats
    game.start_game if game.moves.count == 1
    game.finish_game if game.game_over
  end
end
