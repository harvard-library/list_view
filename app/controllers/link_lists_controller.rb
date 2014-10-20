class LinkListsController < ApplicationController
  def show
    @record = LinkList.find_by(:ext_id => params[:ext_id]) ||
      LinkList.import_xlsx(Roo::Excelx.new("public/spreadsheets/HOLLIS_Links_#{params[:ext_id]}.xlsx"))

    @record.fetch_metadata unless @record.cached_metadata

    @record.save! if @record.changed?

    @mods = JSON.parse(@record.cached_metadata) if @record.cached_metadata
  end

  def edit
    @link_list = LinkList.find_by!(:ext_id => params[:ext_id])
  end

  def new
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

  def destroy
    @link_list = LinkList.find_by!(:ext_id => params[:ext_id])
    if @link_list.destroy.save
      flash[:notice] = "#{@link_list.ext_id} sucessfully destroyed."
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
