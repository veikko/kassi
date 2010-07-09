class CreatePersonInvites < ActiveRecord::Migration
  def self.up
    create_table :person_invites do |t|
      t.string :person
      t.string :direction
      t.string :mail
      t.string :hash

      t.timestamps
    end
  end

  def self.down
    drop_table :person_invites
  end
end
