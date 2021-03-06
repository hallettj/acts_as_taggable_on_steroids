ActiveRecord::Schema.define :version => 0 do
  create_table :tags, :force => true do |t|
    t.column :namespace,  :string
    t.column :short_name, :string
  end

  add_index :tags, [:namespace, :short_name]
  add_index :tags, :namespace
  
  create_table :taggings, :force => true do |t|
    t.column :tag_id, :integer
    t.column :taggable_id, :integer
    t.column :taggable_type, :string
    t.column :created_at, :datetime
  end

  add_index :taggings, :tag_id
  add_index :taggings, [:taggable_id, :taggable_type]
  
  create_table :users, :force => true do |t|
    t.column :name, :string
  end
  
  create_table :posts, :force => true do |t|
    t.column :text, :text
    t.column :cached_tag_list, :string
    t.column :user_id, :integer
    t.column :type, :string
  end
  
  create_table :photos, :force => true do |t|
    t.column :title, :string
    t.column :user_id, :integer
  end
  
  create_table :subscriptions, :force => true do |t|
    t.column :user_id, :integer
    t.column :magazine_id, :integer
  end
  
  create_table :magazines, :force => true do |t|
    t.column :name, :string
  end
end
