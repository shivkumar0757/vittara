require "test_helper"

class GetAccountsToolTest < ActiveSupport::TestCase
  include McpToolTestHelper

  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
  end

  test "returns an array of account hashes" do
    result = call_tool(GetAccountsTool, server_context: @context)

    assert_kind_of Array, result
    assert result.length > 0
  end

  test "each account has required keys" do
    result = call_tool(GetAccountsTool, server_context: @context)

    result.each do |account|
      assert_includes account.keys, :id
      assert_includes account.keys, :name
      assert_includes account.keys, :type
      assert_includes account.keys, :subtype
      assert_includes account.keys, :balance
      assert_includes account.keys, :currency
      assert_includes account.keys, :classification
    end
  end

  test "only returns accounts belonging to current family" do
    result = call_tool(GetAccountsTool, server_context: @context)

    family_account_ids = @family.accounts.visible.pluck(:id)

    result.each do |account|
      assert_includes family_account_ids, account[:id],
        "Account #{account[:id]} does not belong to dylan_family"
    end
  end

  test "returns only visible accounts" do
    total_visible = @family.accounts.visible.count

    result = call_tool(GetAccountsTool, server_context: @context)

    assert_equal total_visible, result.length
  end

  test "accounts are returned in alphabetical order" do
    result = call_tool(GetAccountsTool, server_context: @context)

    names = result.map { |a| a[:name] }
    assert_equal names.sort, names, "Accounts are not in alphabetical order"
  end

  test "classification is asset or liability" do
    result = call_tool(GetAccountsTool, server_context: @context)

    result.each do |account|
      assert_includes %w[asset liability], account[:classification],
        "Unexpected classification: #{account[:classification]}"
    end
  end

  test "asset account has correct classification" do
    result = call_tool(GetAccountsTool, server_context: @context)

    depository = result.find { |a| a[:name] == "Checking Account" }
    assert_not_nil depository
    assert_equal "asset", depository[:classification]
  end

  test "liability account has correct classification" do
    result = call_tool(GetAccountsTool, server_context: @context)

    credit_card = result.find { |a| a[:name] == "Credit Card" }
    assert_not_nil credit_card
    assert_equal "liability", credit_card[:classification]
  end

  test "balance and currency are present for each account" do
    result = call_tool(GetAccountsTool, server_context: @context)

    result.each do |account|
      assert_not_nil account[:balance], "balance should not be nil for #{account[:name]}"
      assert_not_nil account[:currency], "currency should not be nil for #{account[:name]}"
    end
  end

  test "type reflects accountable_type" do
    result = call_tool(GetAccountsTool, server_context: @context)

    depository = result.find { |a| a[:name] == "Checking Account" }
    assert_equal "Depository", depository[:type]
  end
end
