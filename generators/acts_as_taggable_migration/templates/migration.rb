class ActsAsTaggableMigration < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.column :namespace,  :string
      t.column :short_name, :string
    end

    add_index :tags, [:namespace, :short_name]
    add_index :tags, :namespace
    
    create_table :taggings do |t|
      t.column :tag_id, :integer
      t.column :taggable_id, :integer
      
      # You should make sure that the column created is
      # long enough to store the required class names.
      t.column :taggable_type, :string
      
      t.column :created_at, :datetime
    end
    
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type]
  end
  
  def self.down
    drop_table :taggings
    drop_table :tags
  end
end
