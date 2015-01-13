class AddLinksCountToLinkLists < ActiveRecord::Migration

  def change
    add_index :links, :link_list_id
    add_column :link_lists, :links_count, :integer, :null => false, :default => 0
    LinkList.reset_column_information
    reversible do |dir|
      dir.up do
        LinkList.pluck(:id).each do |id|
          LinkList.reset_counters(id, :links)
        end
      end
    end
  end
end
