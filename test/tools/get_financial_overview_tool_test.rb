require "test_helper"

class GetFinancialOverviewToolTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)
    Current.stubs(:family).returns(@family)
  end

  test "returns hash with required keys" do
    result = GetFinancialOverviewTool.new.call
    assert_kind_of Hash, result
    assert_includes result.keys, :net_worth
    assert_includes result.keys, :assets
    assert_includes result.keys, :liabilities
    assert_includes result.keys, :this_month_income
    assert_includes result.keys, :this_month_expenses
    assert_includes result.keys, :currency
  end

  test "net worth matches BalanceSheet" do
    result = GetFinancialOverviewTool.new.call
    sheet = BalanceSheet.new(@family)
    assert_equal sheet.net_worth_money.format, result[:net_worth]
  end

  test "this month income and expenses are formatted strings" do
    result = GetFinancialOverviewTool.new.call
    assert_kind_of String, result[:this_month_income]
    assert_kind_of String, result[:this_month_expenses]
  end

  test "currency matches family currency" do
    result = GetFinancialOverviewTool.new.call
    assert_equal @family.currency, result[:currency]
  end
end
