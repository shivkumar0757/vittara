require "test_helper"

class GetNetWorthToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
  end

  test "returns a hash with required keys" do
    result = call_tool(GetNetWorthTool, server_context: @context)

    assert_kind_of Hash, result
    assert_includes result.keys, :net_worth
    assert_includes result.keys, :assets
    assert_includes result.keys, :liabilities
    assert_includes result.keys, :currency
  end

  test "currency matches family currency" do
    result = call_tool(GetNetWorthTool, server_context: @context)

    assert_equal @family.currency, result[:currency]
  end

  test "net_worth, assets and liabilities are formatted strings" do
    result = call_tool(GetNetWorthTool, server_context: @context)

    assert_kind_of String, result[:net_worth]
    assert_kind_of String, result[:assets]
    assert_kind_of String, result[:liabilities]
  end

  test "formatted values include currency symbol" do
    result = call_tool(GetNetWorthTool, server_context: @context)

    # USD formatted values should contain a dollar sign
    assert_match /\$/, result[:net_worth]
    assert_match /\$/, result[:assets]
    assert_match /\$/, result[:liabilities]
  end

  test "assets are greater than zero when family has asset accounts" do
    # dylan_family has asset accounts (depository, investment, etc.) in fixtures
    assert @family.accounts.visible.assets.any?

    result = call_tool(GetNetWorthTool, server_context: @context)

    sheet = BalanceSheet.new(@family)
    expected_assets = sheet.assets.total_money.format
    assert_equal expected_assets, result[:assets]
  end

  test "liabilities are greater than zero when family has liability accounts" do
    assert @family.accounts.visible.liabilities.any?

    result = call_tool(GetNetWorthTool, server_context: @context)

    sheet = BalanceSheet.new(@family)
    expected_liabilities = sheet.liabilities.total_money.format
    assert_equal expected_liabilities, result[:liabilities]
  end

  test "net worth equals assets minus liabilities" do
    result = call_tool(GetNetWorthTool, server_context: @context)

    sheet = BalanceSheet.new(@family)
    expected_net_worth = sheet.net_worth_money.format
    assert_equal expected_net_worth, result[:net_worth]
  end
end
