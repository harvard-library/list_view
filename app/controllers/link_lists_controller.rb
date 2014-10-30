class LinkListsController < ApplicationController
  def show
    @link_list = LinkList.find_by!(:ext_id => params[:ext_id])

    @link_list.fetch_metadata if @link_list.cached_metadata.blank?

    @link_list.save! if @link_list.changed?

    @mods = JSON.parse(@link_list.cached_metadata) unless @link_list.cached_metadata.blank?

    if @mods
      @title = LinkList.process_title_field(@mods['mods']['titleInfo'])
      @author = LinkList.process_name_field(@mods['mods']['name'])
    end
  end

  def index
    @link_lists = LinkList.all
  end

  def edit
    @link_list = LinkList.find_by!(:ext_id => params[:ext_id])
  end

  def new
    flash.now[:notice] = "This is a new record, and has not been saved to the database."
    @link_list = LinkList.new
  end

  def update
    @link_list = LinkList.find_by!(:ext_id => params[:ext_id])
    @link_list.update!(link_list_params)
    if @link_list.save
      flash[:notice] = "#{@link_list.ext_id} updated successfully!"
      redirect_to :action => :show
    end
  end

  def create
    @link_list = LinkList.new(link_list_params)
    if @link_list.save
      flash[:notice] = "#{@link_list.ext_id} created successfully!"
      respond_to do |format|
        format.html { redirect_to @link_list }
      end
    end
  end

  def import
    # Handle params
    params.require(:import_link_lists).permit(:xlsx)
    file = params[:import_link_lists][:xlsx]

    tfile = Tempfile.new(['excel', '.xlsx'])
    tfile.binmode
    tfile.write file.read


    @link_list = LinkList.import_xlsx(Roo::Excelx.new(tfile.path))

    tfile.close
    tfile.unlink

    flash.now[:notice] = "Your record has been imported, but will not be saved to the database until you submit it."
    respond_to do |format|
      format.html { render :action => :new }
    end
  end

  def destroy
    @link_list = LinkList.find_by!(:ext_id => params[:ext_id])
    if @link_list.destroy.save
      flash[:notice] = "#{@link_list.ext_id} sucessfully deleted."
      respond_to do |format|
        format.html { redirect_to link_lists_path }
      end
    end
  end

  private
    def link_list_params
      params.require(:link_list).permit(:id,
                                        :ext_id,
                                        :ext_id_type,
                                        :url,
                                        :continues_name,
                                        :continues_url,
                                        :continued_by_name,
                                        :continued_by_url,
                                        :fts_search_url,
                                        :comment,
                                        :links_attributes => [:id, :name, :url, :_destroy])
    end
end
