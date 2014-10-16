class LinkListsController < ApplicationController
  def show
    params.permit(:number)
    if params[:number]
      @record = LinkList.find_by_ext_id(params[:number]) ||
        LinkList.import_xlsx(Roo::Excelx.new("public/spreadsheets/HOLLIS_Links_#{params[:number]}.xlsx"))
    else
      @record = LinkList.find(params[:id])
    end
    @record.fetch_metadata unless @record.cached_metadata

    @record.save! if @record.changed?

    @mods = JSON.parse(@record.cached_metadata) if @record.cached_metadata
  end

  def edit
    params.permit(:id)
    @link_list = LinkList.find(params[:id])
  end

  def new
    @link_list = LinkList.new
  end

  def update
    @link_list = LinkList.find(params[:id])
    @link_list.update!(link_list_params)
    if @link_list.save
      flash[:notice] = "#{@link_list.ext_id} Updated successfully!"
      redirect_to :action => :show
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
