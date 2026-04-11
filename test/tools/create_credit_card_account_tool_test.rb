require "test_helper"

class CreateCreditCardAccountToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
    Account.any_instance.stubs(:sync_later)
  end

  test "creates a CreditCard account" do
    assert_difference "Account.count", 1 do
      result = call_tool(CreateCreditCardAccountTool,server_context: @context, name: "Visa Platinum", balance: "2500.0")
      assert result[:success]
    end
  end

  test "returns success hash with id, name, and balance" do
    result = call_tool(CreateCreditCardAccountTool,server_context: @context, name: "Chase Sapphire", balance: "1200.0")

    assert result[:success]
    assert_not_nil result[:id]
    assert_equal "Chase Sapphire", result[:name]
    assert_equal 1200.0, result[:balance].to_f
  end

  test "uses family currency when none provided" do
    result = call_tool(CreateCreditCardAccountTool,server_context: @context, name: "Amex Gold", balance: "800.0")

    assert result[:success]
    created = Account.find(result[:id])
    assert_equal @family.currency, created.currency
  end

  test "stores apr when provided" do
    result = call_tool(CreateCreditCardAccountTool,server_context: @context, name: "High APR Card", balance: "500.0", apr: "24.99")

    assert result[:success]
    account = Account.find(result[:id])
    credit_card = account.accountable
    assert_equal 24.99, credit_card.apr.to_f
  end

  test "stores available_credit when provided" do
    result = call_tool(CreateCreditCardAccountTool,server_context: @context, name: "Big Limit Card", balance: "100.0", available_credit: "9900.0")

    assert result[:success]
    account = Account.find(result[:id])
    credit_card = account.accountable
    assert_equal 9900.0, credit_card.available_credit.to_f
  end
end
