class UserState < ActiveRecord::Migration
  def up
    create_table :users_states do |t|
      t.string :user_id
      t.string :state_id
    end
  end

  def down
    drop_table :users_states
  end
end
