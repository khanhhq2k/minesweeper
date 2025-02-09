class GamesController < ApplicationController
  def index
    @games = Game.order(created_at: :desc)
    
    if params[:email].present?
      @games = @games.where(email: params[:email])
      @total_games = @games.count
    else
      @total_games = Game.count
    end
    
    @games = @games.page(params[:page]).per(10)
  end

  def create
    @game = Game.create_new(
      email: params[:email],
      name: params[:name],
      width: params[:width].to_i,
      height: params[:height].to_i,
      mines: params[:mines].to_i
    )
    redirect_to play_game_path(@game)
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.message
    redirect_to root_path
  end

  def new
    @games = Game.order(created_at: :desc).limit(10)#.where(email: params[:email])
  end

  def play
    @game = Game.find(params[:id])
    Rails.logger.debug "Game dimensions: #{@game.width}x#{@game.height}, Mines: #{@game.mines}"
    Rails.logger.debug "Board: #{@game.board.inspect}"
    Rails.logger.debug "Flag: #{@game.flags.inspect}"

  end

  def click
    @game = Game.find(params[:id])
    unless @game.game_over
      row = params[:row].to_i
      col = params[:col].to_i
      
      if params[:flag]
        @game.toggle_flag(row, col)
      else
        @game.reveal_cell(row, col)
      end
    end
    
    render json: {
      board: @game.board,
      revealed: @game.revealed,
      flags: @game.flags,
      game_over: @game.game_over,
      victory: @game.victory
    }
  end
end
