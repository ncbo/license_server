class License < ApplicationRecord
  enum approval_status: {
      approved: "approved",
      disapproved: "disapproved",
      pending: "pending"
  }
  belongs_to :license_purpose
  attr_accessor :latest, :row_color

  def expired?()
    self.valid_date && self.valid_date.to_date < Date.today
  end

  def about_to_expire?()
    cutoff_date = Date.today + $LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE
    self.valid_date && self.valid_date.to_date >= Date.today && self.valid_date.to_date <= cutoff_date
  end

  def self.latest_licenses(status = :any, *filters)
    sql = "SELECT a.* FROM licenses a INNER JOIN (SELECT MAX(id) AS id FROM licenses GROUP BY appliance_id) b ON a.id = b.id WHERE 1=1"
    sql << " AND a.approval_status = '#{status}'" unless status == :any
    sql << " AND a.valid_date IS NOT NULL" if status == self.approval_statuses[:approved]

    filters.each do |filter|
      sql << " AND a.#{filter}"
    end

    sql << " ORDER BY a.id"
    self.find_by_sql(sql)
  end
end
