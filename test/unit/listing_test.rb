require 'test_helper'

class ListingTest < ActiveSupport::TestCase

  def test_has_required_attributes
    assert !listings(:no_author_id).valid?
    assert !listings(:no_category).valid?
    assert !listings(:no_title).valid?
    assert !listings(:no_content).valid?
    assert !listings(:no_good_thru).valid?
    assert !listings(:no_status).valid?
    assert !listings(:no_language).valid?
    assert listings(:valid_listing).valid?
  end

  def test_date_not_valid_format
    listing = listings(:valid_listing)
    listing.good_thru = "huomenna"
    assert !listing.valid?
  end

  def test_status_validation
    #testing with all valid status
    listing_status_valid = listings(:valid_listing) 

    Listing::VALID_STATUS.each do |valid_status|
      listing_status_valid.status = valid_status
      assert listing_status_valid.valid?
    end

    #testing with invalid status
    listing_status_invalid = listings(:valid_listing)
    listing_status_invalid.status = "testi_status"
    assert !listing_status_invalid.valid?

  end

  def test_language_validation
    #test with valid language codes
    listing_language_valid = listings(:valid_listing)

    Listing::VALID_LANGUAGES.each do |valid_language|
      listing_language_valid.language = valid_language
      assert listing_language_valid.valid?
    end

    #test with invalid language codes
    listing_language_invalid = listings(:valid_listing)
    listing_language_invalid.language = "moi"
    assert !listing_language_invalid.valid?
  end


  def test_length_of_title
    listing_too_long_title = listings(:valid_listing)
    listing_too_long_title.title = "this is a too long title for a listing as far as i know"
    assert !listing_too_long_title.valid?


    listing_too_short_title = listings(:valid_listing)
    listing_too_short_title.title = "w"
    assert !listing_too_short_title.valid?

    listing_minimum_title = listings(:valid_listing)
    listing_minimum_title.title = "mo"
    assert listing_minimum_title.valid?

    listing_maximum_title = listings(:valid_listing)
    listing_maximum_title.title = "this is a valid title for a listing as far as it's"
    assert listing_maximum_title.valid?

  end

  def test_length_of_value_other
    listing_too_long_value_o = listings(:valid_listing)
    listing_too_long_value_o.value_other = "asdfghjklöasdfghjklöasdfghjklöasdfghjklöasdfghjklö."
    assert !listing_too_long_value_o.valid?


    listing_minimum_value_o = listings(:valid_listing)
    listing_minimum_value_o.value_other = "1"                               
    assert listing_minimum_value_o.valid?

    listing_maximum_value_o = listings(:valid_listing)
    listing_maximum_value_o.value_other = "asdfghjklöasdfghjklöasdfghjklöasdfghjklöasdfghjklö"
    assert listing_maximum_value_o.valid?
  end

  def test_times_viewed
    listing_times_viewed_not_int = listings(:valid_listing)
    listing_times_viewed_not_int.times_viewed = 1.2
    assert !listing_times_viewed_not_int.valid?

    listing_times_viewed_nil = listings(:valid_listing)
    listing_times_viewed_nil.times_viewed = nil
    assert listing_times_viewed_nil.valid?
  end

  def test_value_cc
    listing_value_cc_not_int = listings(:valid_listing)
    listing_value_cc_not_int.value_cc = 1.2
    assert !listing_value_cc_not_int.valid?

    listing_value_cc_nil = listings(:valid_listing)
    listing_value_cc_nil.value_cc = nil
    assert listing_value_cc_nil.valid?
  end

  def test_category_validation
    #test with valid categories
    listing_category_valid = listings(:valid_listing)

    Listing::VALID_CATEGORIES.each do |valid_category|
      listing_category_valid.category = valid_category
      assert listing_category_valid.valid?
    end

    #test with invalid language codes
    listing_category_invalid = listings(:valid_listing)
    listing_category_invalid.category = "dippa"
    assert !listing_category_invalid.valid?
  end

end