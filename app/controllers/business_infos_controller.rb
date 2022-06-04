class BusinessInfosController < ApplicationController
  before_action :set_business_info, only: [:show, :edit, :update, :destroy]
  before_action :force_json, only: :search


  # GET /business_infos
  # GET /business_infos.json
  def index
    @business_infos = BusinessInfo.all
  end

  def search
    q = params[:q].downcase
    @business_infos = BusinessInfo.where("class_code ILIKE ? or business_type ILIKE ?", "%#{q}%", "%#{q}%").limit(5)
    # binding.pry
  end

  # GET /business_infos/1
  # GET /business_infos/1.json
  def show
  end

  # GET /business_infos/new
  def new
    @business_info = BusinessInfo.new
  end

  # GET /business_infos/1/edit
  def edit
  end

  # POST /business_infos
  # POST /business_infos.json
  def create
    @business_info = BusinessInfo.new(business_info_params)

    respond_to do |format|
      if @business_info.save
        format.html { redirect_to @business_info, notice: 'Business info was successfully created.' }
        format.json { render :show, status: :created, location: @business_info }
      else
        format.html { render :new }
        format.json { render json: @business_info.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /business_infos/1
  # PATCH/PUT /business_infos/1.json
  def update
    respond_to do |format|
      if @business_info.update(business_info_params)
        format.html { redirect_to @business_info, notice: 'Business info was successfully updated.' }
        format.json { render :show, status: :ok, location: @business_info }
      else
        format.html { render :edit }
        format.json { render json: @business_info.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /business_infos/1
  # DELETE /business_infos/1.json
  def destroy
    @business_info.destroy
    respond_to do |format|
      format.html { redirect_to business_infos_url, notice: 'Business info was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_business_info
      @business_info = BusinessInfo.find(params[:id])
      respond_to do |format|
        format.json { head :no_content }
      end
    end

    # Only allow a list of trusted parameters through.
    def business_info_params
      params.require(:business_info).permit(:business_type, :class_code)
    end

    def force_json
      request.format = :json
    end
end
