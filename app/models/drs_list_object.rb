class DRSListObject
  include ActiveModel::Model
  attr_accessor :title, :links, :ext_id, :ext_id_type
  
  def initialize(title, ext_id, links)
    @title = title
    @ext_id_type = 'drs'
    @ext_id = ext_id
    @links = links
  end
  
  def to_param
    "#{@ext_id_type}-#{@ext_id}"
  end

end