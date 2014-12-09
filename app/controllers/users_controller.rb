class UsersController < ApplicationController
  before_action :authenticate_login!

  # Helper methods

  def vet_password
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if params[:user][:password] != params[:user][:password_confirmation]
      flash[:error] = 'Password and confirmation must match.'
      redirect_to :back
    end
  end

  def vet_username
    if params[:user][:username].blank?
      params[:user][:username] = nil
    end
  end
  # Collection actions

  def index
    @users = User.order(:id)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    vet_username
    vet_password
    if @user.save
      flash[:notice] = "User sucessfully created!"
      redirect_to @user, :action => :show
    else
      flash[:error] = "Failed to save user."
      redirect_to :back
    end
  end

  # Member actions

  def show
    @user = User.find(params[:id])
    @actions = Ledger
               .where(:user_email => @user.email)
               .order('created_at DESC')
               .limit(100)
               .pluck(:ext_id_type, :ext_id, :event_type, :created_at)
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    vet_username
    vet_password

    @user.attributes = user_params
    if @user.save
      flash[:notice] = "User updated sucessfully!"
      respond_to do |f|
        f.html { redirect_to @user, :action => :show }
      end
      return
    else
      flash[:error] = "Failed to update user."
      redirect_to :back
      return false
    end
  end

  def destroy
    @user = User.find(params[:id])
    unless @user == current_user
      dead = @user.destroy!
      flash[:success] = "#{dead.username || dead.email} deleted."
    else
      flash[:error] = "You may not delete yourself.  Get someone else to delete you."
    end
    respond_to do |f|
      f.html { redirect_to users_path }
    end
  end

  private
  def user_params
    params.require(:user).permit(:email, :username, :affiliation, :password, :password_confirmation)
  end
end
