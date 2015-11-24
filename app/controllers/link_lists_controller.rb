class LinkListsController < ApplicationController
  before_action :authenticate_login!, :except => [:index, :show, :meta]

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
    flash.now[:warning] = "This is a new record, and has not been saved to the database."
    @link_list = LinkList.new
  end

  def create
    @link_list = LinkList.new(link_list_params)
    @link_list.last_touched_by = current_user.email
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

    if file.original_filename.match /\.xlsx$/
      tfile = Tempfile.new(['excel', '.xlsx'])
    else
      tfile = Tempfile.new(['csv', '.csv'])
    end
    tfile.binmode
    tfile.write file.read
    tfile.close

    if file.original_filename.match /\.xlsx$/
      @link_list = LinkList.import_xlsx(Roo::Excelx.new(tfile.path))
    else
      @link_list = LinkList.import_csv(CSV.read(tfile.path))
    end

    tfile.unlink

    flash.now[:warning] = "Your record has been imported, but will not be saved to the database until you submit it."
    respond_to do |format|
      format.html { render :action => :new }
    end
  end

  # AJAX route
  def meta
    params.permit(:ext_id, :ext_id_type)
    md = Metadata.new(params.slice(:ext_id, :ext_id_type))
    md.fetch_metadata

    ll = LinkList.find_by(md.to_h.slice(:ext_id, :ext_id_type))

    if ll
      if md.body.blank?
        if ll && ll.cached_metadata
          md.body = ll.cached_metadata
          md.populate
        end
      else
        ll.cached_metadata = md.body
        ll.save!
      end
    end
    respond_to do |f|
      f.json { render :json => md.as_json }
    end
  end


  ### Member actions

  def show
    splitid = split_qualified_id(params[:qualified_id])
    if splitid[:ext_id_type] == 'drs'
      @link_list = DRSLinkList.display_object(splitid[:ext_id])
      @page_title = !(@link_list.mets_title.blank?) ? @link_list.mets_title : @link_list.osn_id
      
    else
      @link_list = LinkList.includes(:links).find_by!(split_qualified_id(params[:qualified_id]))
      @page_title = @link_list.title  
    end
      
    @title = @link_list.title
    @authors = !@link_list.author.blank? ? @link_list.author.split("\n") : []
    @publication = !@link_list.publication.blank? ? @link_list.publication.split("\n") : []

    
    respond_to do |f|
      f.html
      f.csv {
        headers['Content-Disposition'] = "attachment; filename=\"#{@link_list.ext_id_type}-#{@link_list.ext_id}.csv\""
        headers['Content-Type'] ||= 'text/csv'
      }
    end

  end

  def edit
    @link_list = LinkList.includes(:links).find_by!(split_qualified_id(params[:qualified_id]))
  end

  def update
    @link_list = LinkList.find_by!(split_qualified_id(params[:qualified_id]))
    @link_list.last_touched_by = current_user.email
    @link_list.attributes = link_list_params

    if @link_list.save
      flash[:notice] = "#{@link_list.ext_id} updated successfully!"
      redirect_to :action => :show
    else
      flash[:error] = "Failed to update #{@link_list.ext_id}!"
      redirect_to :back
    end
  end

  def destroy
    @link_list = LinkList.find_by!(split_qualified_id(params[:qualified_id]))
    @link_list.last_touched_by = current_user.email
    if @link_list.destroy
      flash[:notice] = "#{@link_list.ext_id} sucessfully deleted."
      respond_to do |format|
        format.html { redirect_to link_lists_path }
      end
    end
  end
  
  def test
    testmodel = Test.new()
    @mystring = testmodel.get_string()
  end

  private
    def link_list_params
      params.require(:link_list).permit(:ext_id,
                                        :ext_id_type,
                                        :qualified_id,
                                        :title,
                                        :author,
                                        :publication,
                                        :image,
                                        :remove_image,
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
      #HashWithIndifferentAccess.new([:ext_id_type, :ext_id].zip(q_id.split('-',2)).to_h)
      HashWithIndifferentAccess.new(Hash[[:ext_id_type, :ext_id].zip(q_id.split('-',2))])
    end

end
