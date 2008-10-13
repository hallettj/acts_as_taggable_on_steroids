require File.dirname(__FILE__) + '/abstract_unit'

class TagTest < Test::Unit::TestCase
  fixtures :tags, :taggings, :users, :photos, :posts

  setup :reset_namespace_separator
  
  def test_name_required
    t = Tag.create
    assert_match /blank/, t.errors[:name].to_s
  end
  
  def test_name_unique
    t = Tag.create!(:name => "My tag")
    duplicate = t.clone

    assert !duplicate.save
    assert_match /taken/, duplicate.errors[:name].to_s
  end

  def test_namespaced_name_unique
    t = Tag.create!(:name => "my:tag")
    duplicate = t.clone
    assert !duplicate.save
    assert_match /taken/, duplicate.errors[:name].to_s
  end
  
  def test_taggings
    assert_equivalent [taggings(:jonathan_sky_good), taggings(:sam_flowers_good), taggings(:sam_flower_good), taggings(:ruby_good)], tags(:good).taggings
    assert_equivalent [taggings(:sam_ground_bad), taggings(:jonathan_bad_cat_bad)], tags(:bad).taggings
  end
  
  def test_to_s
    assert_equal tags(:good).name, tags(:good).to_s
  end
  
  def test_equality
    assert_equal tags(:good), tags(:good)
    assert_equal Tag.find(1), Tag.find(1)
    assert_equal Tag.new(:name => 'A'), Tag.new(:name => 'A')
    assert_not_equal Tag.new(:name => 'A'), Tag.new(:name => 'B')
  end

  def test_name_assignment
    t = Tag.new
    t.name = "music"
    assert_equal "music", t.name
    t.name = "music:cajun"
    assert_equal "music:cajun", t.name
  end

  def test_output_of_namespaced_tag
    t = Tag.create!(:name => "music:cajun")
    assert_equal "music:cajun", t.to_s
  end

  def test_output_of_namespaced_tag_with_custom_namespace_separator
    t = Tag.create!(:name => "music/cajun")
    assert_equal "music/cajun", t.to_s
  end

  def test_category_and_name_from_tag
    assert_equal ["music", nil], Tag.category_and_name_from_tag("music")
    assert_equal ["music", "cajun"], Tag.category_and_name_from_tag("music:cajun")
  end

  def test_category_and_name_from_tag_with_custom_separator
    Tag.namespace_separator = "/"
    assert_equal ["music", nil], Tag.category_and_name_from_tag("music")
    assert_equal ["music", "cajun"], Tag.category_and_name_from_tag("music/cajun")
  end

  def test_category_and_name_from_tag_with_custom_separator_that_contains_whitespace
    Tag.namespace_separator = " > "
    assert_equal ["music", nil], Tag.category_and_name_from_tag("music")
    assert_equal ["music", "cajun"], Tag.category_and_name_from_tag("music > cajun")
  end

  def test_category_and_name_from_tag_ignores_whitespace_around_namespace_separator
    category, name = Tag.category_and_name_from_tag("music : cajun")
    assert_equal category, "music"
    assert_equal name, "cajun"
    Tag.namespace_separator = " > "
    category, name = Tag.category_and_name_from_tag("food>cajun")
    assert_equal category, "food"
    assert_equal name, "cajun"
  end

  protected

  def reset_namespace_separator
    Tag.namespace_separator = ":"
  end

end
