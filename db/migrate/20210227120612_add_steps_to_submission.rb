class AddStepsToSubmission < ActiveRecord::Migration[6.1]
  def change
    add_column :submissions, :form_steps, :integer, default: 0
  end
end
