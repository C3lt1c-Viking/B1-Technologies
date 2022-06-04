class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy

  def index
    @users = User.paginate(page: params[:page])
  end

  def admin
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      reset_session
      log_in @user
      flash[:success] = "Welcome to B1 Technologies!"
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def agency_information
    @user = User.find(current_user.id)
    # binding.pry
    @user = @user.settings(:agency_information)
    # binding.pry

  end

  def rails_settings_setting_user
    @user = current_user
    @user.settings(:agency_information).producer_id = params[:rails_settings_setting_object][:producer_id]
    @user.settings(:agency_information).on_behalf_of = params[:rails_settings_setting_object][:on_behalf_of]
    @user.settings(:agency_information).producer_email = params[:rails_settings_setting_object][:producer_email]
    @user.settings(:agency_information).on_behalf_of_email = params[:rails_settings_setting_object][:on_behalf_of_email]
    @user.settings(:agency_information).agency_license_number = params[:rails_settings_setting_object][:agency_license_number]
    @user.settings(:agency_information).broker_license_number = params[:rails_settings_setting_object][:broker_license_number]
    @user.settings(:agency_information).agency_address = params[:rails_settings_setting_object][:agency_address]
    @user.settings(:agency_information).agency_address2 = params[:rails_settings_setting_object][:agency_address2]
    @user.settings(:agency_information).agency_city = params[:rails_settings_setting_object][:agency_city]
    @user.settings(:agency_information).agency_state = params[:rails_settings_setting_object][:agency_state]
    @user.settings(:agency_information).agency_zip_code = params[:rails_settings_setting_object][:agency_zip_code]
    @user.settings(:agency_information).agency_phone_number = params[:rails_settings_setting_object][:agency_phone_number]
    @user.settings(:agency_information).agency_fax_number = params[:rails_settings_setting_object][:agency_fax_number]
    @user.settings(:agency_information).save!
    flash[:success] = "Agency information has been updated"
    redirect_back(fallback_location: root_path)
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:agency, :name, :email, :password, :password_confirmation, :agency_code)
    end

    # Confirms a logged-in user.
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end

    # Confirms the correct user.
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

    # Confirms an admin user.
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end

end
