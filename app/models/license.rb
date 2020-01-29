class License < ApplicationRecord
  enum approval_status: {
      approved: "approved",
      disapproved: "disapproved",
      pending: "pending"
  }
  belongs_to :license_purpose
end
