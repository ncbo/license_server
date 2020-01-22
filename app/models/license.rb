class License < ApplicationRecord
  enum approval_status: {
      approved: "approved",
      disapproved: "disapproved",
      pending: "pending"
  }
  has_one :license_purpose
end
