class License < ApplicationRecord
  enum approval_status: {
      approved: "approved",
      disapproved: "disapproved",
      pending: "pending"
  }
  belongs_to :license_purpose
  attr_accessor :latest
  attr_accessor :row_color

  def expired?()
    self.valid_date && self.valid_date.to_date < Date.today
  end
end
