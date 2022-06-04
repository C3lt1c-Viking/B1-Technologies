class Submission < ApplicationRecord
  belongs_to :user
  enum submission_type: [:commercial_liability, :general_liability, :in_land_marine]

end
