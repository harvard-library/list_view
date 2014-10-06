class CreateLinkList < ActiveRecord::Migration
  def change
    create_table :link_lists do |t|
      t.string :ext_id, :null => false
      t.string :ext_id_type, :null => false, :default => 'hollis'
      t.string :url, :null => false
      t.string :continues_name
      t.string :continues_url
      t.string :continued_by_name
      t.string :continued_by_url
      t.string :fts_search_url
      t.text :comment
      t.text :cached_metadata
    end
  end
end
