class UploadsController < ApplicationController
  def index
    @uploads = Upload.with_attached_file.includes(:transfers).order(created_at: :desc)
  end

  def show
    @upload = Upload.find(params[:id])
    @transfers = @upload.transfers.includes(:from_account, :to_account)
  end

  def new
    @upload = Upload.new(business_date: Date.current)
  end

  def create
    @upload = Upload.new(upload_params)

    if @upload.save
      ProcessUploadJob.perform_later(@upload)
      redirect_to uploads_path, notice: "Upload is being processed"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def upload_params
    params.require(:upload).permit(:business_date, :file)
  end
end
