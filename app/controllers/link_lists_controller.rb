class LinkListsController < ApplicationController
  def show
    params.permit(:number)
    unless params[:number].blank?
      @record = LinkList.import_xlsx(Roo::Excelx.new("public/spreadsheets/HOLLIS_Links_#{params[:number]}.xlsx"))
    end
  end
end
