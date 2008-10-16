require File.dirname(__FILE__) + '/abstract_unit'

class TagTest < Test::Unit::TestCase
  fixtures :tags, :taggings, :users, :photos, :posts

  setup :reset_namespace_separator
  
  def test_name_required
    t = Tag.new
    assert !t.valid?
    assert_match /blank/, t.errors[:namespace].to_s
  end
  
  def test_name_unique
    t = Tag.create!(:name => "My tag")
    duplicate = t.clone

    assert !duplicate.valid?
    assert_match /taken/, duplicate.errors[:short_name].to_s
  end

  def test_namespaced_name_unique
    t = Tag.create!(:name => "my:tag")
    duplicate = t.clone
    assert !duplicate.valid?
    assert_match /taken/, duplicate.errors[:short_name].to_s
  end

  def test_find_by_name
    music_cajun = Tag.create!(:name => "music:cajun")
    music = Tag.create!(:name => "music")
    assert_equal music, Tag.find_by_name("music")
    assert_equal music_cajun, Tag.find_by_name("music:cajun")
  end

  def test_find_all_by_name
    music_cajun = Tag.create!(:name => "music:cajun")
    music = Tag.create!(:name => "music")
    assert !Tag.find_all_by_name("music").include?(music_cajun)
    assert Tag.find_all_by_name("music").length == 1
  end

  def test_find_or_create_with_like_by_name_creates_new_tag
    music_cajun = Tag.create!(:name => "music:cajun")
    new_tag = Tag.find_or_create_with_like_by_name("music")
    assert_equal "music", new_tag.name
    assert new_tag != music_cajun
  end

  def test_find_or_create_with_like_by_name_finds_existing_tag
    music_cajun = Tag.create!(:name => "music:cajun")
    found_tag = Tag.find_or_create_with_like_by_name("music:cajun")
    assert_equal music_cajun, found_tag
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

  def test_namespace_and_short_name_from_tag
    assert_equal ["music", nil], Tag.namespace_and_short_name_from_tag("music")
    assert_equal ["music", "cajun"], Tag.namespace_and_short_name_from_tag("music:cajun")
  end

  def test_namespace_and_short_name_from_tag_with_custom_separator
    Tag.namespace_separator = "/"
    assert_equal ["music", nil], Tag.namespace_and_short_name_from_tag("music")
    assert_equal ["music", "cajun"], Tag.namespace_and_short_name_from_tag("music/cajun")
  end

  def test_namespace_and_short_name_from_tag_with_custom_separator_that_contains_whitespace
    Tag.namespace_separator = " > "
    assert_equal ["music", nil], Tag.namespace_and_short_name_from_tag("music")
    assert_equal ["music", "cajun"], Tag.namespace_and_short_name_from_tag("music > cajun")
  end

  def test_namespace_and_short_name_from_tag_ignores_whitespace_around_namespace_separator
    namespace, name = Tag.namespace_and_short_name_from_tag("music : cajun")
    assert_equal namespace, "music"
    assert_equal name, "cajun"
    Tag.namespace_separator = " > "
    namespace, name = Tag.namespace_and_short_name_from_tag("food>cajun")
    assert_equal namespace, "food"
    assert_equal name, "cajun"
  end

  def test_merging_tag_with_non_unique_name
    [:jonathan_sky, :jonathan_grass, :jonathan_rain].each do |post|
      posts(post).tag_list = "foo"
      posts(post).save!
    end
    [:sam_ground, :sam_flowers].each do |post|
      posts(post).tag_list = "bar"
      posts(post).save!
    end
    foo = Tag.find_by_name("foo")
    bar = Tag.find_by_name("bar")
    assert_equal 3, foo.taggings.count
    assert_equal 2, bar.taggings.count

    bar.name = "foo"
    merged = bar.merge!

    assert_equal foo, merged
    assert_equal 5, foo.reload.taggings.count
    assert bar.frozen?
    assert_equal 0, Tagging.find_all_by_tag_id(bar.id).length
  end

  def test_merging_tag_with_unique_name
    [:jonathan_sky, :jonathan_grass, :jonathan_rain].each do |post|
      posts(post).tag_list = "foo"
      posts(post).save!
    end
    [:sam_ground, :sam_flowers].each do |post|
      posts(post).tag_list = "bar"
      posts(post).save!
    end
    foo = Tag.find_by_name("foo")
    bar = Tag.find_by_name("bar")
    assert_equal 3, foo.taggings.count
    assert_equal 2, bar.taggings.count

    merged = bar.merge!

    assert_equal bar, merged
    assert_equal 3, foo.reload.taggings.count
    assert !bar.frozen?
    assert_equal 2, Tagging.find_all_by_tag_id(bar.id).length
  end

  protected

  def reset_namespace_separator
    Tag.namespace_separator = ":"
  end

end
