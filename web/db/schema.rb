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

ActiveRecord::Schema[7.1].define(version: 2025_05_30_105940) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "inventory_levels", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.bigint "variant_id", null: false
    t.integer "quantity", null: false
    t.integer "minimum_quantity", default: 0, null: false
    t.decimal "health_percentage", precision: 10, scale: 2, null: false
    t.string "shopify_inventory_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id", "variant_id", "shopify_inventory_item_id"], name: "index_inventory_levels_on_location_variant_and_shopify_item", unique: true
    t.index ["location_id"], name: "index_inventory_levels_on_location_id"
    t.index ["variant_id"], name: "index_inventory_levels_on_variant_id"
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "shopify_location_id", null: false
    t.string "name", null: false
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "shopify_location_id"], name: "index_locations_on_shop_id_and_shopify_location_id", unique: true
    t.index ["shop_id"], name: "index_locations_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "access_scopes"
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "shopify_user_id", null: false
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "access_scopes", default: "", null: false
    t.datetime "expires_at"
    t.index ["shopify_user_id"], name: "index_users_on_shopify_user_id", unique: true
  end

  create_table "variants", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "shopify_product_id", null: false
    t.string "shopify_variant_id", null: false
    t.string "variant_title", null: false
    t.boolean "is_tracked", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_variants_on_shop_id"
    t.index ["shopify_variant_id"], name: "index_variants_on_shopify_variant_id", unique: true
  end

  add_foreign_key "inventory_levels", "locations"
  add_foreign_key "inventory_levels", "variants"
  add_foreign_key "locations", "shops"
  add_foreign_key "variants", "shops"
end
