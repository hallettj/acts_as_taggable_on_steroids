class Tag < ActiveRecord::Base
  cattr_accessor :namespace_separator
  self.namespace_separator = ':'

  has_many :taggings, :dependent => :destroy
  
  validates_presence_of :namespace
  validates_uniqueness_of :short_name, :scope => :namespace
  validates_each :namespace, :short_name, :allow_nil => true do |tag, attr, value|
    tag.errors.add attr, 'cannot be an empty string.' if value.blank?
  end
  
  cattr_accessor :destroy_unused
  self.destroy_unused = false

  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(tag)
    find_by_name(tag) || create(:name => tag)
  end

  def self.find_by_name(tag, options={})
    namespace, short_name = namespace_and_short_name_from_tag(tag)
    if namespace and short_name
      find(:first, options.merge(:conditions => ["namespace like ? and short_name like ?", namespace, short_name]))
    else
      find(:first, options.merge(:conditions => ["namespace like ? and short_name is null", namespace]))
    end
  end

  def self.find_all_by_name(tag, options={})
    namespace, short_name = namespace_and_short_name_from_tag(tag)
    if namespace and short_name
      find(:all, options.merge(:conditions => ["namespace like ? and short_name like ?", namespace, short_name]))
    else
      find(:all, options.merge(:conditions => ["namespace like ? and short_name is null", namespace]))
    end
  end

  # Returns a list of all tag categories
  def self.namespaces
    dbh = ActiveRecord::Base.connection
    rs = dbh.select_all(<<-HERE)
      select distinct 
        namespace
      from 
        #{table_name}
      order by
        namespace
    HERE
    rs.map { |r| r["namespace"] }.compact
  end

  # Given a combined short_name and namespace in namespace notation, returns
  # the namespace and short_name separately.
  def self.namespace_and_short_name_from_tag(tag, separator=Tag.namespace_separator)
    # namespace separators can contain whitespace
    separator_regex = separator.sub(/^\s+/,'\\s*').sub(/\s+$/,'\\s*')
    separator_chars = separator.gsub(/\s+/,'')
    if tag =~ /^([^#{separator_chars}]+)#{separator_regex}([^#{separator_chars}]+)$/
      namespace = $1.strip
      short_name = $2.strip
    else
      namespace = tag
      short_name = nil
    end
    [namespace, short_name]
  end

  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  # Returns the fully qualified name of the tag using namespace
  # notation.
  #
  # If the tag's short_name is "cajun" and its namespace is "music",
  # returns "music:cajun".
  # 
  # It is possible to have a tag with a namespace, but no
  # short_name. In that case the fully qualified name is the namespace
  # by itself.
  def name
    [self[:namespace], self[:short_name]].reject(&:blank?).join(Tag.namespace_separator)
  end

  # Sets both the namespace and the short_name at once based on namespace
  # notation.
  #
  # Passing "music:cajun" sets the namespace to "cajun" and the tag
  # short_name to "music".
  #
  # Passing "cajun" sets the tag namespace to "cajun" and the tag
  # short_name to NULL.
  def name=(n)
    namespace, short_name = Tag.namespace_and_short_name_from_tag(n)
    self[:namespace] = namespace
    self[:short_name] = short_name
  end

  def namespace=(n)
    self[:namespace] = n.blank? ? nil : n
  end

  def short_name=(n)
    self[:short_name] = n.blank? ? nil : n
  end
  
  def to_s
    name
  end
  
  def count
    read_attribute(:count).to_i
  end

  # Checks for an existing tag with the same name. If one exists,
  # updates all of this tag's taggings to point to that tag and
  # returns that tag. Otherwise just returns this tag.
  def merge!
    other_tag = Tag.find_by_name(self.name)
    if other_tag.nil? or other_tag.id == self.id
      return self
    else
      taggings.map(&:clone).each { |t| (t.tag = other_tag) && t.save! }
      self.destroy
      return other_tag
    end
  end

end
