require "test_helper"

class CreateCreditCardAccountToolTest < ActiveSupport::TestCase
  setup do
    Current.stubs(:family).returns(families(:dylan_family))
    Account.any_instance.stubs(:sync_later)
  end

  def build_tool
    tool = CreateCreditCardAccountTool.new
    tool.stubs(:require_write_access!)
    tool
  end

  test "creates a CreditCard account" do
    tool = build_tool
    assert_difference "Account.count", 1 do
      result = tool.call(name: "Visa Platinum", balance: 2500.0)
      assert result[:success]
    end
  end

  test "returns success hash with id, name, and balance" do
    tool = build_tool
    result = tool.call(name: "Chase Sapphire", balance: 1200.0)

    assert result[:success]
    assert_not_nil result[:id]
    assert_equal "Chase Sapphire", result[:name]
    assert_equal 1200.0, result[:balance]
  end

  test "uses family currency when none provided" do
    family = families(:dylan_family)
    tool = build_tool
    result = tool.call(name: "Amex Gold", balance: 800.0)

    assert result[:success]
    created = Account.find(result[:id])
    assert_equal family.currency, created.currency
  end

  test "stores apr when provided" do
    tool = build_tool
    result = tool.call(name: "High APR Card", balance: 500.0, apr: 24.99)

    assert result[:success]
    account = Account.find(result[:id])
    credit_card = account.accountable
    assert_equal 24.99, credit_card.apr.to_f
  end

  test "stores available_credit when provided" do
    tool = build_tool
    result = tool.call(name: "Big Limit Card", balance: 100.0, available_credit: 9900.0)

    assert result[:success]
    account = Account.find(result[:id])
    credit_card = account.accountable
    assert_equal 9900.0, credit_card.available_credit.to_f
  end
end
