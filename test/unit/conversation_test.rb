require 'test_helper'

class ConversationTest < ActiveSupport::TestCase

  def test_has_required_attributes
    conversations(:one).valid?
    assert_conversation_valid(:title, nil, false)
  end

  def test_listing_id_int
    assert_conversation_valid(:listing_id, "testi", false)
    assert_conversation_valid(:listing_id, 1.2, false)
  end
  
  def test_title_length
    assert_conversation_valid(:title, "sanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanassanasanasanasanasana", false)
    assert_conversation_valid(:title, "w", false)
    assert_conversation_valid(:title, "sanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasanasana", true)
    assert_conversation_valid(:title, "mo", true)
  end
  
  def test_message_association
    assert_equal [ messages(:two), messages(:valid_message) ], conversations(:one).messages   
  end
  
  def test_participant_association
    assert conversations(:one).participants.include?(people(:one))
    assert conversations(:one).participants.include?(people(:two))
  end
  
  private
  
  def assert_conversation_valid(attribute, value, is_valid)
    conversation = conversations(:one)
    conversation.update_attribute(attribute, value)
    if is_valid
      assert conversation.valid?
    else
      assert !conversation.valid?
    end    
  end
  
end
