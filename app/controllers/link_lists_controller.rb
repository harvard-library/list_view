class LinkListsController < ApplicationController
  def show
    params.permit(:number)
    unless params[:number].blank?
      @record = LinkList.find_by_ext_id(params[:number]) ||
                LinkList.import_xlsx(Roo::Excelx.new("public/spreadsheets/HOLLIS_Links_#{params[:number]}.xlsx"))

      @record.fetch_metadata unless @record.cached_metadata

      @record.save! if @record.changed?

      @mods = JSON.parse(@record.cached_metadata) if @record.cached_metadata
    end
  end
end
