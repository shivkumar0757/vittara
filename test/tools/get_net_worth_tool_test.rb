require "test_helper"

class GetNetWorthToolTest < ActiveSupport::TestCase
  setup do
    Current.stubs(:family).returns(families(:dylan_family))
  end

  test "returns a hash with required keys" do
    tool = GetNetWorthTool.new
    result = tool.call

    assert_kind_of Hash, result
    assert_includes result.keys, :net_worth
    assert_includes result.keys, :assets
    assert_includes result.keys, :liabilities
    assert_includes result.keys, :currency
  end

  test "currency matches family currency" do
    family = families(:dylan_family)
    tool = GetNetWorthTool.new
    result = tool.call

    assert_equal family.currency, result[:currency]
  end

  test "net_worth, assets and liabilities are formatted strings" do
    tool = GetNetWorthTool.new
    result = tool.call

    assert_kind_of String, result[:net_worth]
    assert_kind_of String, result[:assets]
    assert_kind_of String, result[:liabilities]
  end

  test "formatted values include currency symbol" do
    tool = GetNetWorthTool.new
    result = tool.call

    # USD formatted values should contain a dollar sign
    assert_match /\$/, result[:net_worth]
    assert_match /\$/, result[:assets]
    assert_match /\$/, result[:liabilities]
  end

  test "assets are greater than zero when family has asset accounts" do
    family = families(:dylan_family)
    # dylan_family has asset accounts (depository, investment, etc.) in fixtures
    assert family.accounts.visible.assets.any?

    tool = GetNetWorthTool.new
    result = tool.call

    sheet = BalanceSheet.new(family)
    expected_assets = sheet.assets.total_money.format
    assert_equal expected_assets, result[:assets]
  end

  test "liabilities are greater than zero when family has liability accounts" do
    family = families(:dylan_family)
    assert family.accounts.visible.liabilities.any?

    tool = GetNetWorthTool.new
    result = tool.call

    sheet = BalanceSheet.new(family)
    expected_liabilities = sheet.liabilities.total_money.format
    assert_equal expected_liabilities, result[:liabilities]
  end

  test "net worth equals assets minus liabilities" do
    family = families(:dylan_family)
    tool = GetNetWorthTool.new
    result = tool.call

    sheet = BalanceSheet.new(family)
    expected_net_worth = sheet.net_worth_money.format
    assert_equal expected_net_worth, result[:net_worth]
  end
end
