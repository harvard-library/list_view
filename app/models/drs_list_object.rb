class DRSListObject
  include ActiveModel::Model
  
  attr_accessor :title, :links, :ext_id, :ext_id_type, :author, :publication, :image, :comment, :continues_url, :continued_by_url, :url, :fts_search_url
  
  def initialize(title, author, ext_id, links)
    @title = title
    @author = author
    @ext_id_type = 'drs'
    @ext_id = ext_id
    @links = links
    @fts_search_url = ""
    @dateable = false
  end
  
  def to_param
    "#{@ext_id_type}-#{@ext_id}"
  end
  
  def dateable?
    @dateable
  end

end