class CreateBusinessInfos < ActiveRecord::Migration[6.1]
  def change
    create_table :business_infos do |t|
      t.string :business_type
      t.string :class_code

      t.timestamps
    end
  end
end
