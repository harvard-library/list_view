class DRSLinkList
  include ActiveModel::Model
  
  def self.all
    @list_objects = DRSServices.drs_object("400004800")
    #@list_objects = []
    #@list_objects.push DRSListObject.new('Test 1', '1', ['abc', '123'])
    #@list_objects.push DRSListObject.new('Test 2', '2', ['def', '456'])
  end
  

end
