class LinkListsController < ApplicationController
  before_action :authenticate_login!, :except => [:index, :show]

  #### Collection actions

  def index
    params.permit(:ext_id_type)
    @link_lists = LinkList.all
    if params[:ext_id_type]
      @typed = params[:ext_id_type]
      @link_lists = @link_lists.where(:ext_id_type => params[:ext_id_type])
    end
  end

  def new
    flash.now[:notice] = "This is a new record, and has not been saved to the database."
    @link_list = LinkList.new
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

  def types
    @types = LinkList.distinct(:ext_id_type).pluck(:ext_id_type)
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

  ### Member actions

  def show
    @link_list = LinkList.find_by!(split_qualified_id(params[:qualified_id]))

    @link_list.fetch_metadata if @link_list.cached_metadata.blank?

    @title = !@link_list.title.blank? ? @link_list.title : '<No title recorded>'
    @authors = @link_list.author.split("\n")
    @publication = !@link_list.publication.blank? ? @link_list.publication.split("\n") : ['<No publication data recorded>']

    @link_list.save! if @link_list.changed?

  end

  def edit
    @link_list = LinkList.find_by!(split_qualified_id(params[:qualified_id]))
  end

  def update
    @link_list = LinkList.find_by!(split_qualified_id(params[:qualified_id]))
    @link_list.update!(link_list_params)
    if @link_list.save
      flash[:notice] = "#{@link_list.ext_id} updated successfully!"
      redirect_to :action => :show
    end
  end

  def destroy
    @link_list = LinkList.find_by!(split_qualified_id(params[:qualified_id]))
    if @link_list.destroy.save
      flash[:notice] = "#{@link_list.ext_id} sucessfully deleted."
      respond_to do |format|
        format.html { redirect_to link_lists_path }
      end
    end
  end

  private
    def link_list_params
      params.require(:link_list).permit(:ext_id,
                                        :ext_id_type,
                                        :qualified_id,
                                        :url,
                                        :continues_name,
                                        :continues_url,
                                        :continued_by_name,
                                        :continued_by_url,
                                        :fts_search_url,
                                        :dateable,
                                        :comment,
                                        :links_attributes => [:id, :name, :url, :_destroy])
    end

    ### Helper Methods ###
    def split_qualified_id(q_id)
      #FIXME Needs to split on FIRST dash
      HashWithIndifferentAccess.new([:ext_id_type, :ext_id].zip(q_id.split('-')).to_h)
    end

end
