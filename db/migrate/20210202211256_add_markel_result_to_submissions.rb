class AddMarkelResultToSubmissions < ActiveRecord::Migration[6.1]
  def change
    add_column :submissions, :markel_results, :jsonb
  end
end
