require 'test_helper'

class LicenseTest < ActiveSupport::TestCase
  test "expired? is true only when valid_date is strictly in the past" do
    assert License.new(valid_date: Date.today - 1).expired?
    refute License.new(valid_date: Date.today).expired?
    refute License.new(valid_date: Date.today + 1).expired?
    refute License.new(valid_date: nil).expired?
  end

  test "about_to_expire? is true within the advance-notice window" do
    within = Date.today + ($LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE - 1)
    beyond = Date.today + ($LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE + 5)
    assert License.new(valid_date: within).about_to_expire?
    refute License.new(valid_date: beyond).about_to_expire?
    refute License.new(valid_date: Date.today - 1).about_to_expire?, "already expired"
    refute License.new(valid_date: nil).about_to_expire?
  end

  test "latest_licenses returns one (newest) row per appliance_id" do
    ids = License.latest_licenses.map(&:appliance_id)
    assert_equal ids.uniq.sort, ids.sort, "expected one row per appliance_id"
  end
end
