require "test_helper"

class CreateLoanAccountToolTest < ActiveSupport::TestCase
  setup do
    Current.stubs(:family).returns(families(:dylan_family))
    Account.any_instance.stubs(:sync_later)
  end

  def build_tool
    tool = CreateLoanAccountTool.new
    tool.stubs(:require_write_access!)
    tool
  end

  test "creates a Loan account with interest_rate and term_months" do
    tool = build_tool
    assert_difference "Account.count", 1 do
      result = tool.call(
        name: "Home Mortgage",
        balance: 300_000.0,
        interest_rate: 6.5,
        term_months: 360
      )
      assert result[:success]
    end
  end

  test "returns success hash with id, name, and balance" do
    tool = build_tool
    result = tool.call(name: "Auto Loan", balance: 15_000.0)

    assert result[:success]
    assert_not_nil result[:id]
    assert_equal "Auto Loan", result[:name]
    assert_equal 15_000.0, result[:balance]
  end

  test "uses balance as initial_balance when not provided" do
    tool = build_tool
    result = tool.call(name: "Personal Loan", balance: 8_000.0)

    assert result[:success]
    account = Account.find(result[:id])
    loan = account.accountable
    assert_equal 8_000.0, loan.initial_balance.to_f
  end

  test "uses family currency when none provided" do
    family = families(:dylan_family)
    tool = build_tool
    result = tool.call(name: "Student Loan", balance: 20_000.0)

    assert result[:success]
    created = Account.find(result[:id])
    assert_equal family.currency, created.currency
  end

  test "stores interest_rate and term_months on loan accountable" do
    tool = build_tool
    result = tool.call(
      name: "Mortgage with Rate",
      balance: 450_000.0,
      interest_rate: 7.25,
      term_months: 240
    )

    assert result[:success]
    account = Account.find(result[:id])
    loan = account.accountable
    assert_equal 7.25, loan.interest_rate.to_f
    assert_equal 240, loan.term_months
  end
end
