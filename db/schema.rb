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

ActiveRecord::Schema.define(version: 20200121230018) do

  create_table "license_purposes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.integer "sort_order", null: false
    t.index ["sort_order"], name: "index_license_purposes_on_sort_order", unique: true
  end

  create_table "licenses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "bp_username", null: false
    t.string "last_name", null: false
    t.string "first_name", null: false
    t.string "organization", limit: 512, null: false
    t.text "project_info"
    t.text "reason"
    t.text "identification"
    t.text "comments"
    t.string "appliance_id", null: false
    t.string "license_key", limit: 1024
    t.date "valid_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "approval_status", limit: 11, default: "pending", null: false
    t.bigint "license_purpose_id", null: false
    t.index ["appliance_id"], name: "index_licenses_on_appliance_id"
    t.index ["approval_status"], name: "index_licenses_on_approval_status"
    t.index ["bp_username"], name: "index_licenses_on_bp_username"
    t.index ["license_purpose_id"], name: "fk_rails_7a164d2de3"
  end

  add_foreign_key "licenses", "license_purposes"
end
