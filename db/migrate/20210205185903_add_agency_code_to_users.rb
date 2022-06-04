class AddAgencyCodeToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :agency_code, :string
  end
end
