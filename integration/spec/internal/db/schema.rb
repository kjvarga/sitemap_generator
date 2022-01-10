  ActiveRecord::Schema.define(:version => 1) do
    create_table "contents", force: true do |t|
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
