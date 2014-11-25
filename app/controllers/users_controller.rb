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
    else
      flash[:error] = "Failed to update user."
      redirect_to :back
    end
  end


  private
  def user_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation)
  end
end
