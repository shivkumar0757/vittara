require "test_helper"

class CreateAccountToolTest < ActiveSupport::TestCase
  def setup
    Current.stubs(:family).returns(families(:dylan_family))
    Account.any_instance.stubs(:sync_later)
  end

  def build_tool
    tool = CreateAccountTool.new
    tool.stubs(:require_write_access!)
    tool
  end

  test "creates a Depository account successfully" do
    tool = build_tool
    assert_difference "Account.count", 1 do
      result = tool.call(name: "Test Checking", accountable_type: "Depository", balance: 1000.0)
      assert result[:success]
    end
  end

  test "returns success hash with id, name, type, and balance" do
    tool = build_tool
    result = tool.call(name: "Test Savings", accountable_type: "Depository", balance: 2500.0)

    assert result[:success]
    assert_not_nil result[:id]
    assert_equal "Test Savings", result[:name]
    assert_equal "Depository", result[:type]
    assert_equal 2500.0, result[:balance]
  end

  test "rejects invalid accountable_type with error message" do
    tool = build_tool
    result = tool.call(name: "Bad Account", accountable_type: "Mortgage", balance: 1000.0)

    assert_equal false, result[:success]
    assert_includes result[:errors].first, "accountable_type must be one of"
  end

  test "uses family currency when none provided" do
    family = families(:dylan_family)
    tool = build_tool
    result = tool.call(name: "Auto Currency Account", accountable_type: "Depository", balance: 500.0)

    assert result[:success]
    created = Account.find(result[:id])
    assert_equal family.currency, created.currency
  end

  test "creates Investment account" do
    tool = build_tool
    result = tool.call(name: "My Brokerage", accountable_type: "Investment", balance: 5000.0)
    assert result[:success]
    assert_equal "Investment", result[:type]
  end

  test "creates Crypto account" do
    tool = build_tool
    result = tool.call(name: "My Crypto", accountable_type: "Crypto", balance: 3000.0)
    assert result[:success]
    assert_equal "Crypto", result[:type]
  end

  test "creates OtherAsset account" do
    tool = build_tool
    result = tool.call(name: "Gold Bar", accountable_type: "OtherAsset", balance: 10000.0)
    assert result[:success]
    assert_equal "OtherAsset", result[:type]
  end

  test "creates OtherLiability account" do
    tool = build_tool
    result = tool.call(name: "Personal Debt", accountable_type: "OtherLiability", balance: 500.0)
    assert result[:success]
    assert_equal "OtherLiability", result[:type]
  end
end
