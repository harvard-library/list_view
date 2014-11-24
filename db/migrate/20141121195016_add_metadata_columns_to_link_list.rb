class AddMetadataColumnsToLinkList < ActiveRecord::Migration
  def change
    add_column :link_lists, :title, :text
    add_column :link_lists, :author, :text
    add_column :link_lists, :publication, :text

    reversible do |dir|
      dir.up do
        LinkList.all.each do |ll|
          if ll.cached_metadata
            md = JSON.parse(ll.cached_metadata)['mods']
            ll.title = LinkList.process_title_field(md['titleInfo'], md['note']) if md['titleInfo']
            ll.author = LinkList.process_name_field(md['name']) if md['name']
            ll.publication = LinkList.process_pub_field(md['originInfo']) if md['originInfo']
            ll.save!
          end
        end
      end
      dir.down do
        # No-op
      end
    end

  end
end
