class AddAdminUser < ActiveRecord::Migration
  def self.up
    add_column :users, :admin, :boolean, :null => false, :default => 0
  end

  def self.down
    remove_column :users, :admin
  end
end
