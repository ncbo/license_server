require 'test_helper'

# Characterizes the auth + access-control + approval behavior so the Rails upgrade
# (and the upcoming security-debt fixes) can't silently change it. The two BP API
# calls (User.authenticate, User.get) are stubbed via BpApiStubs#with_bp.
class AuthAndAccessTest < ActionDispatch::IntegrationTest
  test "anonymous is redirected to login when visiting /licenses" do
    get '/licenses'
    assert_response :redirect
    assert_match %r{/login}, @response.redirect_url
  end

  test "successful login lands on the licenses page" do
    user = fake_bp_user(username: 'owneruser')
    with_bp(user) do
      login_as(user)
      assert_redirected_to licenses_path
      follow_redirect!
      assert_response :success
      assert_match(/Licenses/, @response.body)
    end
  end

  test "failed login (no apikey) re-renders the login form with an error" do
    bad = fake_bp_user(apikey: nil)
    with_bp(bad) do
      login_as(bad)
      assert_response :success
      assert_match %r{Invalid username/password}, @response.body
    end
  end

  test "a non-admin owner sees only their own licenses" do
    owner = fake_bp_user(username: 'owneruser', admin: false)
    with_bp(owner) do
      login_as(owner)
      get '/licenses'
      assert_response :success
      assert_match '22222222-222', @response.body  # owner's appliance is shown
      refute_match '33333333-333', @response.body  # another user's is not
    end
  end

  test "an admin sees all licenses" do
    admin = fake_bp_user(username: 'admin', admin: true)
    with_bp(admin) do
      login_as(admin)
      get '/licenses'
      assert_response :success
      assert_match '33333333-333', @response.body  # another user's appliance visible to admin
    end
  end

  test "admin approval generates a key once, sets valid_date, and emails the user" do
    admin = fake_bp_user(username: 'admin', admin: true, email: 'user@example.com')
    target = licenses(:owner_pending)
    assert_nil target.license_key

    with_bp(admin) do
      login_as(admin)
      assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
        post approve_license_path(target)
      end
    end

    target.reload
    assert target.license_key.present?, "license_key should be generated on approval"
    assert target.valid_date.present?, "valid_date should be set on approval"
    assert_equal 'approved', target.approval_status
  end

  test "a non-admin cannot self-approve via create (strong params blocks it)" do
    owner = fake_bp_user(username: 'owneruser', email: 'owneruser@example.com')
    with_bp(owner) do
      login_as(owner)
      assert_difference -> { License.count }, 1 do
        post '/licenses', params: { license: {
          appliance_id: '44444444-4444-4444-8444-444444444444',
          first_name: 'Owner', last_name: 'User', organization: 'Org One',
          project_info: 'info', reason: 'reason',
          license_purpose_id: license_purposes(:research_individual).id,
          approval_status: 'approved' # malicious: must be ignored for non-admins
        } }
      end
    end
    created = License.order(:id).last
    assert_equal 'pending', created.approval_status, "non-admin must not self-approve"
    assert_nil created.license_key
  end

  # Regression test for ncbo/license_server#20: a BioPortal account with no first/
  # last name used to 500 on the "Create License" form (nil.strip). This is the
  # kind of bug the new test suite + CI catch.
  test "the create form renders for an account with no first/last name (#20)" do
    user = fake_bp_user(username: 'noname', first: nil, last: nil)
    with_bp(user) do
      login_as(user)
      get '/licenses/new'
      assert_response :success
    end
  end
end
