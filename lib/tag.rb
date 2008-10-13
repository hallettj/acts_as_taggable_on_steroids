class Tag < ActiveRecord::Base
  cattr_accessor :namespace_separator
  self.namespace_separator = ':'

  has_many :taggings
  
  # See validate method below
  
  cattr_accessor :destroy_unused
  self.destroy_unused = false

  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(tag)
    find(:first, :conditions => tags_condition(tag)) || create(:name => tag)
  end

  def self.find_by_name(tag)
    find(:first, :conditions => tags_condition(tag))
  end

  def self.find_all_by_name(tag)
    find(:all, :conditions => tags_condition(tag))
  end

  # Returns a list of all tag categories
  def self.categories
    dbh = ActiveRecord::Base.connection
    rs = dbh.select_all(<<-HERE).first
      select distinct 
        category
      from 
        #{table_name}
      order by
        category
    HERE
    rs.map { |r| r["category"] }
  end

  # Given a combined name and category in namespace notation, returns
  # the category and name separately.
  def self.category_and_name_from_tag(tag, separator=Tag.namespace_separator)
    # namespace separators can contain whitespace
    separator_regex = separator.sub(/^\s+/,'\\s*').sub(/\s+$/,'\\s*')
    separator_chars = separator.gsub(/\s+/,'')
    if tag =~ /^([^#{separator_chars}]+)#{separator_regex}([^#{separator_chars}]+)$/
      category = $1.strip
      name = $2.strip
    else
      category = tag
      name = nil
    end
    [category, name]
  end

  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  # Returns the combined name and category of the tag using namespace
  # notation.
  # 
  # If the tag's name is "cajun" and its category is "music", returns
  # "music:cajun".
  # 
  # It is possible to have a tag with a category, but no name. In that
  # case the category is returned by itself.
  def name
    [self[:category], self[:name]].reject(&:blank?).join(Tag.namespace_separator)
  end

  # Sets both the category and the name at once based on namespace
  # notation.
  #
  # Passing "music:cajun" sets the category to "cajun" and the tag
  # name to "music".
  #
  # Passing "cajun" sets the tag category to "cajun" and the tag
  # name to NULL.
  def name=(n)
    category, name = Tag.category_and_name_from_tag(n)
    self[:category] = category
    self[:name] = name
  end
  
  def to_s
    name
  end
  
  def count
    read_attribute(:count).to_i
  end

  protected

  def validate
    # In terms of database columns, it is category that can't be
    # blank. But we want the error report to complain about the name
    # attribute, because users should be using the name accessors and
    # not the category accessors.
    if name.blank?
      errors.add(:name, "cannot be blank.")
    end

    # validates_uniqueness_of does not seem to be doing the trick, for
    # some reason. So this validation is performed manually.
    if self.class.find_by_category_and_name(self[:category], self[:name])
      errors.add(:name, "is taken.")
    end
  end

  class << self
    def tags_condition(tags, table_name = Tag.table_name)
      condition = tags.map { |tag|
        category, name = Tag.category_and_name_from_tag(tag)
        if category and name
          sanitize_sql(["(#{table_name}.category LIKE ? AND #{table_name}.name LIKE ?)", category, name])
        else
          sanitize_sql(["#{table_name}.category LIKE ?", category])
        end
      }.join(" OR ")
      "(" + condition + ")"
    end
  end

end
