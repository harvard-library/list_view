class RemoveUrlFromLinkList < ActiveRecord::Migration
  class LinkList < ActiveRecord::Base
    # empty class to guard against AR shenanigans in migration
  end

  def up
    remove_column :link_lists, :url 
  end

  def down
    add_column :link_lists, :url, :null => false
    LinkList.reset_column_information
    LinkList.all.each do |ll|
      ll.url = Erubis::Eruby
        .new(MetadataSources[ll.ext_id_type]['templates']['record_url'])
        .result(:ext_id => ext_id, :ext_id_type => ext_id_type)
      ll.save!
    end
  end
end
