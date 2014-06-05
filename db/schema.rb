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

ActiveRecord::Schema.define(version: 20140605202151) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "discussion_threads", force: true do |t|
    t.string   "title"
    t.integer  "subforum_id"
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_posted_to"
  end

  add_index "discussion_threads", ["created_by_id"], name: "index_discussion_threads_on_created_by_id", using: :btree
  add_index "discussion_threads", ["subforum_id"], name: "index_discussion_threads_on_subforum_id", using: :btree

  create_table "posts", force: true do |t|
    t.text     "body"
    t.integer  "thread_id"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subforum_groups", force: true do |t|
    t.string   "name",       null: false
    t.integer  "ordinal",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subforums", force: true do |t|
    t.string   "name"
    t.integer  "subforum_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "avatar_url"
    t.string   "batch_name"
    t.integer  "hacker_school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["hacker_school_id"], name: "index_users_on_hacker_school_id", using: :btree

  create_table "visited_statuses", force: true do |t|
    t.integer  "user_id"
    t.datetime "last_visited"
    t.integer  "visitable_id"
    t.string   "visitable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "visited_statuses", ["user_id"], name: "index_visited_statuses_on_user_id", using: :btree
  add_index "visited_statuses", ["visitable_id", "visitable_type"], name: "index_visited_statuses_on_visitable_id_and_visitable_type", using: :btree

end
