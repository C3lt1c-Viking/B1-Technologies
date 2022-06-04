require "test_helper"

class BusinessInfosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @business_info = business_infos(:one)
  end

  test "should get index" do
    get business_infos_url
    assert_response :success
  end

  test "should get new" do
    get new_business_info_url
    assert_response :success
  end

  test "should create business_info" do
    assert_difference('BusinessInfo.count') do
      post business_infos_url, params: { business_info: { business_type: @business_info.business_type, class_code: @business_info.class_code } }
    end

    assert_redirected_to business_info_url(BusinessInfo.last)
  end

  test "should show business_info" do
    get business_info_url(@business_info)
    assert_response :success
  end

  test "should get edit" do
    get edit_business_info_url(@business_info)
    assert_response :success
  end

  test "should update business_info" do
    patch business_info_url(@business_info), params: { business_info: { business_type: @business_info.business_type, class_code: @business_info.class_code } }
    assert_redirected_to business_info_url(@business_info)
  end

  test "should destroy business_info" do
    assert_difference('BusinessInfo.count', -1) do
      delete business_info_url(@business_info)
    end

    assert_redirected_to business_infos_url
  end
end
