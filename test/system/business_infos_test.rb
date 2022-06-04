require "application_system_test_case"

class BusinessInfosTest < ApplicationSystemTestCase
  setup do
    @business_info = business_infos(:one)
  end

  test "visiting the index" do
    visit business_infos_url
    assert_selector "h1", text: "Business Infos"
  end

  test "creating a Business info" do
    visit business_infos_url
    click_on "New Business Info"

    fill_in "Business type", with: @business_info.business_type
    fill_in "Class code", with: @business_info.class_code
    click_on "Create Business info"

    assert_text "Business info was successfully created"
    click_on "Back"
  end

  test "updating a Business info" do
    visit business_infos_url
    click_on "Edit", match: :first

    fill_in "Business type", with: @business_info.business_type
    fill_in "Class code", with: @business_info.class_code
    click_on "Update Business info"

    assert_text "Business info was successfully updated"
    click_on "Back"
  end

  test "destroying a Business info" do
    visit business_infos_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Business info was successfully destroyed"
  end
end
