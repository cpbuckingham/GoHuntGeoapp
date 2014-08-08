class StatesVisited < ActiveRecord::Migration
  def up
    create_table :states_visited do |t|
      t.integer :user_id
      t.integer :state_id
    end
  end

  def down
    drop_table :states_visited
  end
end
