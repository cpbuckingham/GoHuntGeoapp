class State < ActiveRecord::Migration
  def up
    create_table :states do |t|
      t.string :name
      t.integer :value
      t.string :abbreviation
      t.integer :expense

    end
  end

  def down
    drop_table :states
  end
end
