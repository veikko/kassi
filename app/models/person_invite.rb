class PersonInvite < ActiveRecord::Base
  
  validates_presence_of :person
  validates_presence_of :direction
  validates_presence_of :hash
  validates_presence_of :mail
  
end
