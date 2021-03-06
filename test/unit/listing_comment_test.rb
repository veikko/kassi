require 'test_helper'

class ListingCommentTest < ActiveSupport::TestCase
  
  def test_has_required_attributes
    comment = listing_comments(:valid_listing_comment)

    #valid with required attributes
    assert comment.valid?

    #invalid without author id
    comment.author_id = nil
    assert !comment.valid?

    #invalid without listing id
    comment = listing_comments(:valid_listing_comment)
    comment.listing_id = nil
    assert !comment.valid?
    
    comment = listing_comments(:valid_listing_comment)
    comment.content = nil
    assert !comment.valid?
  end

  def test_listing_id_int
    comment = listing_comments(:valid_listing_comment)

    comment.listing_id = "testi"
    assert !comment.valid?

    comment.listing_id = "1.2"
    assert !comment.valid?

  end
  
  def test_listing_association
    assert_equal listings(:valid_listing), listing_comments(:another_comment).listing
  end  

end
