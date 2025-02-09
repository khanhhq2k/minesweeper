class Game < ApplicationRecord
  has_many :moves, dependent: :destroy
  
  validates :name, :email, presence: true
  validates :width, :height, :mines, presence: true, numericality: { greater_than: 0 }
  validates :board, :revealed, :flags, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :mines_less_than_board_size
  
  after_find :ensure_arrays
  
  def self.create_new(email:, name:, width: 8, height: 8, mines: 10)
    width = width.to_i
    height = height.to_i
    mines = mines.to_i
    
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

  def won?
    return false if game_over && !victory
    unrevealed_safe_cells = 0
    height.times do |row|
      width.times do |col|
        if !revealed[row][col] && board[row][col] != -1
          unrevealed_safe_cells += 1
        end
      end
    end
    unrevealed_safe_cells == 0
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
          empty_board[row][col] = -1 # -1 is a mine
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
    
    @last_revealed_row = row
    @last_revealed_col = col
    
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
    
    if won?
      self.game_over = true
      save!
    else
      save!
    end
  end
  
  def toggle_flag(row, col)
    return if revealed[row][col]
    
    flags_board = flags
    flags_board[row][col] = !flags_board[row][col]
    self.flags = flags_board
    save!
  end

  def victory
    return false if game_over && board[last_revealed_row][last_revealed_col] == -1
    
    # Check if all non-mine cells are revealed
    height.times do |row|
      width.times do |col|
        # If there's an unrevealed cell that's not a mine, game isn't won yet
        if !revealed[row][col] && board[row][col] != -1
          return false
        end
      end
    end
    
    # All non-mine cells are revealed
    true
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

  def ensure_arrays
    self.board = board.is_a?(Array) ? board : JSON.parse(board)
    self.revealed = revealed.is_a?(Array) ? revealed : JSON.parse(revealed)
    self.flags = flags.is_a?(Array) ? flags : JSON.parse(flags)
  end

  def last_revealed_row
    @last_revealed_row || 0
  end

  def last_revealed_col
    @last_revealed_col || 0
  end
end
