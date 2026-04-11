require "test_helper"

class CreateAccountToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
    Account.any_instance.stubs(:sync_later)
  end

  test "creates a Depository account successfully" do
    assert_difference "Account.count", 1 do
      result = call_tool(CreateAccountTool,server_context: @context, name: "Test Checking", accountable_type: "Depository", balance: "1000.0")
      assert result[:success]
    end
  end

  test "returns success hash with id, name, type, and balance" do
    result = call_tool(CreateAccountTool,server_context: @context, name: "Test Savings", accountable_type: "Depository", balance: "2500.0")

    assert result[:success]
    assert_not_nil result[:id]
    assert_equal "Test Savings", result[:name]
    assert_equal "Depository", result[:type]
    assert_equal 2500.0, result[:balance].to_f
  end

  test "rejects invalid accountable_type with error message" do
    result = call_tool(CreateAccountTool,server_context: @context, name: "Bad Account", accountable_type: "Mortgage", balance: "1000.0")

    assert_equal false, result[:success]
    assert_includes result[:errors].first, "accountable_type must be one of"
  end

  test "uses family currency when none provided" do
    result = call_tool(CreateAccountTool,server_context: @context, name: "Auto Currency Account", accountable_type: "Depository", balance: "500.0")

    assert result[:success]
    created = Account.find(result[:id])
    assert_equal @family.currency, created.currency
  end

  test "creates Investment account" do
    result = call_tool(CreateAccountTool,server_context: @context, name: "My Brokerage", accountable_type: "Investment", balance: "5000.0")
    assert result[:success]
    assert_equal "Investment", result[:type]
  end

  test "creates Crypto account" do
    result = call_tool(CreateAccountTool,server_context: @context, name: "My Crypto", accountable_type: "Crypto", balance: "3000.0")
    assert result[:success]
    assert_equal "Crypto", result[:type]
  end

  test "creates OtherAsset account" do
    result = call_tool(CreateAccountTool,server_context: @context, name: "Gold Bar", accountable_type: "OtherAsset", balance: "10000.0")
    assert result[:success]
    assert_equal "OtherAsset", result[:type]
  end

  test "creates OtherLiability account" do
    result = call_tool(CreateAccountTool,server_context: @context, name: "Personal Debt", accountable_type: "OtherLiability", balance: "500.0")
    assert result[:success]
    assert_equal "OtherLiability", result[:type]
  end
end
