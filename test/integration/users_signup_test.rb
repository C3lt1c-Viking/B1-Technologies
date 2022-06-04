require "test_helper"

class UsersSignupTest < ActionDispatch::IntegrationTest

  test "invalid signup information" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: { user: { name:  "",
                                         agency: "",
                                         email: "user@invalid",
                                         agency_code: "",
                                         password:              "foo",
                                         password_confirmation: "bar" } }
    end
    assert_template 'users/new'
  end

  test "valid signup information" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name:  "Brent Davis",
                                         agency: "Texas Specialty Underwriters",
                                         email: "brentd@texasspecialty.com",
                                         agency_code: "1234",
                                         password:              "P@s$w0Rd123",
                                         password_confirmation: "P@s$w0Rd123" } }
    end
    follow_redirect!
    assert_template 'users/show'
    assert is_logged_in?
  end

end
