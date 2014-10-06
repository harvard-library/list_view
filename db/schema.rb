# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141006160238) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "link_lists", force: true do |t|
    t.string "ext_id",                               null: false
    t.string "ext_id_type",       default: "hollis", null: false
    t.string "url",                                  null: false
    t.string "continues_name"
    t.string "continues_url"
    t.string "continued_by_name"
    t.string "continued_by_url"
    t.string "fts_search_url"
    t.text   "comment"
    t.text   "cached_metadata"
  end

  create_table "links", force: true do |t|
    t.integer "position",     default: 0, null: false
    t.integer "link_list_id",             null: false
    t.string  "name",                     null: false
    t.string  "url",                      null: false
  end

end
