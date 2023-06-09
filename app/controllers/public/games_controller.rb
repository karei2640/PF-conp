class Public::GamesController < ApplicationController
  
  def index
    @games = Game.page(params[:page]).per(150)
    @latest_games = Game.order(created_at: :desc).page(params[:latest_games_page]).per(150)
    @customer = current_customer
  end
  
  def popular_index
    @games = Game.page(params[:page]).per(150)
    @popular_games_all = Game.joins(:view_counts).group(:id).order('count(view_counts.id) desc').page(params[:popular_games_all_page]).per(150) 
    # Game.joins(:view_counts): Game モデルと ViewCount モデルを関連付け
    @popular_games_monthly = Game.joins(:view_counts).where(view_counts: { created_at: 1.month.ago..Time.current }).group(:id).order('count(view_counts.id) desc').page(params[:popular_games_monthly_page]).per(150) 
    # group(:id): Game モデルの id 列で結果をグループ化  
    @popular_games_weekly = Game.joins(:view_counts).where(view_counts: { created_at: 1.week.ago..Time.current }).group(:id).order('count(view_counts.id) desc').page(params[:popular_games_weekly_page]).per(150) 
    # 同じゲームの複数の閲覧数が結合され、ゲームごとに集計できる
    @popular_games_daily = Game.joins(:view_counts).where(view_counts: { created_at: 1.day.ago..Time.current }).group(:id).order('count(view_counts.id) desc').page(params[:popular_games_daily_page]).per(150)
    # order('count(view_counts.id) desc'): 閲覧数のカウントを降順（高い順）で結果を並べ替える
    @customer = current_customer
  end
  
  def favorite_index
    @games = Game.page(params[:page]).per(150)
    @favorite_games = Game.joins(:favorites).group(:id).order('count(favorites.id) desc').page(params[:favorite_games_page]).per(150)
    @favorite_games_all = Game.joins(:favorites).group(:id).order('count(favorites.id) desc').page(params[:favorite_games_all_page]).per(150)
    @favorite_games_monthly = Game.joins(:favorites).where(favorites: { created_at: 1.month.ago..Time.current }).group(:id).order('count(favorites.id) desc').page(params[:favorite_games_monthly_page]).per(150)
    @favorite_games_weekly = Game.joins(:favorites).where(favorites: { created_at: 1.week.ago..Time.current }).group(:id).order('count(favorites.id) desc').page(params[:favorite_games_weekly_page]).per(150)
    @favorite_games_daily = Game.joins(:favorites).where(favorites: { created_at: 1.day.ago..Time.current }).group(:id).order('count(favorites.id) desc').page(params[:favorite_games_daily_page]).per(150)
    @customer = current_customer
  end  
  
  def show
    @game = Game.find(params[:id])
    if current_customer
      current_customer.view_counts.create(game: @game)
    else
      ViewCount.create(game: @game)
    end
    @comments = @game.comments.page(params[:page]).per(20)
    @comment = Comment.new
  end
  
  def new
    @game = Game.new
  end
  
  def create
    @game = Game.new(game_params)
    @game.customer_id = current_customer.id
    if @game.save
      redirect_to game_path(@game), notice: '投稿を更新しました。'
    else
      flash.now[:alert] = "投稿に失敗しました。必要な項目を全て入力してください。"
      render 'new'
    end
  end
  
 def edit
  if current_customer.nil?
    redirect_to new_customer_session_path, alert: "ログインが必要です。"
  else
    @game = current_customer.games.find_by(id: params[:id])
    if @game.nil?
      redirect_to root_path, alert: "アクセス権限がありません。"
    end
  end
 end

  
  def update
    @game = Game.find(params[:id])
    if @game.update(game_params)
      redirect_to game_path(@game), notice: '投稿を更新しました。'
    else
      flash.now[:alert] = "投稿に失敗しました。必要な項目を全て入力してください。"
      render 'edit'
    end
  end
  
  def destroy
    @game = Game.find(params[:id])
    @game.destroy
    if admin_signed_in?
    redirect_to admin_games_path, alert: '投稿を削除しました。'  # 管理者ページにリダイレクト
    else
    redirect_to games_path, alert: '投稿を削除しました。'  # 一般顧客はゲーム一覧ページにリダイレクト
    end
  end
  
  
  private
  
  def count_views(games, period)
    @views_all = count_views(@popular_games_all, Time.zone.now.all_month)
    @views_monthly = count_views(@popular_games_monthly, 1.month.ago.all_month)
    @views_weekly = count_views(@popular_games_weekly, 1.week.ago.all_week)
    @views_daily = count_views(@popular_games_daily, 1.day.ago.all_day)
    views = {}
    games.each do |game|
      views[game.id] = game.views.where(created_at: period).count
    end
    views
  end
  
  def game_params
    params.require(:game).permit(:game_title, :platform_id, :category_id,:image1, :image2,  :genre_id, :points, :release_date, :price, :image, :introduct_title, :introduct, :good_introduct, :bad_introduct, :overall_review,:game_comment)
  end
  
  def game_comment_params
    params.require(:game_comment).permit(:comment)
  end


  def ensure_correct_customer
    @game = Game.find(params[:id])
    unless @game.customer == current_customer.id
      redirect_to games_path
    end
  end
end 


