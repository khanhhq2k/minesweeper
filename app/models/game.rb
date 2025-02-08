class Game < ApplicationRecord
  has_many :moves, dependent: :destroy
  
  validates :name, :email, presence: true
  validates :width, :height, :mines, presence: true, numericality: { greater_than: 0 }
  validates :board, :revealed, :flags, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :mines_less_than_board_size
  
  def self.create_new(email:, name:, width: 8, height: 8, mines: 10)
    game = new(
      email: email,
      name: name,
      width: width,
      height: height,
      mines: mines,
      revealed: Array.new(height) { Array.new(width, false) },
      flags: Array.new(height) { Array.new(width, false) },
      game_over: false
    )
    
    game.generate_board
    game.save!
    game
  end
  
  def generate_board
    empty_board = Array.new(height) { Array.new(width, 0) }
    mine_positions = []
    
    # Place mines randomly
    mines.times do
      loop do
        row = rand(height)
        col = rand(width)
        unless mine_positions.include?([row, col])
          mine_positions << [row, col]
          empty_board[row][col] = -1 # -1 represents a mine
          break
        end
      end
    end

    # Calculate numbers for adjacent cells
    mine_positions.each do |row, col|
      adjacent_cells(row, col).each do |r, c|
        empty_board[r][c] += 1 if empty_board[r][c] != -1
      end
    end
    
    self.board = empty_board
  end
  
  def adjacent_cells(row, col)
    cells = []
    (-1..1).each do |i|
      (-1..1).each do |j|
        new_row = row + i
        new_col = col + j
        if new_row.between?(0, height-1) && new_col.between?(0, width-1)
          cells << [new_row, new_col]
        end
      end
    end
    cells
  end
  
  def reveal_cell(row, col)
    return if revealed[row][col] || flags[row][col]
    
    revealed_board = revealed
    revealed_board[row][col] = true
    self.revealed = revealed_board
    
    if board[row][col] == -1
      self.game_over = true
      save!
      return
    end
    
    if board[row][col] == 0
      adjacent_cells(row, col).each do |r, c|
        reveal_cell(r, c) unless revealed[r][c]
      end
    end
    
    save!
  end
  
  def toggle_flag(row, col)
    return if revealed[row][col]
    
    flags_board = flags
    flags_board[row][col] = !flags_board[row][col]
    self.flags = flags_board
    save!
  end

  private

  def mines_less_than_board_size
    if mines.present? && width.present? && height.present?
      max_mines = width * height - 1
      if mines >= max_mines
        errors.add(:mines, "must be less than #{max_mines}")
      end
    end
  end
end
