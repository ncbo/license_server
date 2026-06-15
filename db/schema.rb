# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2020_01_21_230018) do
  create_table "license_purposes", charset: "utf8mb3", collation: "utf8mb3_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "sort_order", null: false
    t.index ["sort_order"], name: "index_license_purposes_on_sort_order", unique: true
  end

  create_table "licenses", charset: "utf8mb3", collation: "utf8mb3_general_ci", force: :cascade do |t|
    t.string "bp_username", null: false
    t.string "last_name", null: false
    t.string "first_name", null: false
    t.string "organization", limit: 512
    t.text "project_info"
    t.text "reason"
    t.text "identification"
    t.text "comments"
    t.string "appliance_id", null: false
    t.string "license_key", limit: 1024
    t.date "valid_date"
    t.boolean "expiration_reminder_sent", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "approval_status", limit: 11, default: "pending", null: false
    t.bigint "license_purpose_id", null: false
    t.index ["appliance_id"], name: "index_licenses_on_appliance_id"
    t.index ["approval_status"], name: "index_licenses_on_approval_status"
    t.index ["bp_username"], name: "index_licenses_on_bp_username"
    t.index ["expiration_reminder_sent"], name: "index_licenses_on_expiration_reminder_sent"
    t.index ["license_purpose_id"], name: "fk_rails_7a164d2de3"
  end

  add_foreign_key "licenses", "license_purposes"
end
