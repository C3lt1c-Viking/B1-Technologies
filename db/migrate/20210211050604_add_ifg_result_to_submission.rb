class AddIfgResultToSubmission < ActiveRecord::Migration[6.1]
  def change
    add_column :submissions, :ifg_result, :jsonb
  end
end
