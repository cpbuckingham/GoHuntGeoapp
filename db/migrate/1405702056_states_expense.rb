class StatesExpense < ActiveRecord::Migration
  def up
    create_table :states_expense do |t|
      t.integer :user_id
      t.integer :state_id
    end
  end

  def down
    drop_table :states_expense
  end
end
