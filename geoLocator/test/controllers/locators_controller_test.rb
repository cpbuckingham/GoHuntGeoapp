require 'test_helper'

class LocatorsControllerTest < ActionController::TestCase
  setup do
    @locator = locators(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:locators)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create locator" do
    assert_difference('Locator.count') do
      post :create, locator: {  }
    end

    assert_redirected_to locator_path(assigns(:locator))
  end

  test "should show locator" do
    get :show, id: @locator
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @locator
    assert_response :success
  end

  test "should update locator" do
    patch :update, id: @locator, locator: {  }
    assert_redirected_to locator_path(assigns(:locator))
  end

  test "should destroy locator" do
    assert_difference('Locator.count', -1) do
      delete :destroy, id: @locator
    end

    assert_redirected_to locators_path
  end
end
