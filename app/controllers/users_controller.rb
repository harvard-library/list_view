class UsersController < ApplicationController
  before_action :authenticate_login!

  def index
    @users = User.order(:id)
  end

  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.attributes = user_params
    if @user.save
      flash.now[:notice] = "User updated sucessfully!"
      render @user
    else
      flash[:error] = "Failed to update user."
      redirect_to :back
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash.now[:notice] = "User sucessfully created!"
      render @user
    else
      flash[:error] = "Failed to save user."
      redirect_to :back
    end
  end

  private
  def user_params
    params.require(:user).permit(:email, :password)
  end
end
