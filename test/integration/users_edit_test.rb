require "test_helper"

class UsersEditTest < ActionDispatch::IntegrationTest


    def setup
      @user = users(:brent)
    end

    test "unsuccessful edit" do
      log_in_as(@user)
      get edit_user_path(@user)
      assert_template 'users/edit'
      patch user_path(@user), params: { user: { name:                  "",
                                                agency:                "",
                                                agency_code:           "",
                                                email:                 "foo@invalid",
                                                password:              "foo",
                                                password_confirmation: "bar" } }

      assert_template 'users/edit'
    end

    test "successful edit with friendly forwarding" do
      get edit_user_path(@user)
      log_in_as(@user)
      assert_redirected_to edit_user_url(@user)
      name        = "Brent Davis"
      agency      = "Texas Specialty Underwriters"
      agency_code = "0295"
      email       = "foo@bar.com"
      patch user_path(@user), params: { user: { name:                  name,
                                                agency:                agency,
                                                agency_code:           agency_code,
                                                email:                 email,
                                                password:              "",
                                                password_confirmation: "" } }
      assert_not flash.empty?
      assert_redirected_to @user
      @user.reload
      assert_equal name,        @user.name
      assert_equal agency,      @user.agency
      assert_equal agency_code, @user.agency_code
      assert_equal email,       @user.email
    end

end
