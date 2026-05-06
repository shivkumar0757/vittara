require "test_helper"

class CreateLoanAccountToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
    Account.any_instance.stubs(:sync_later)
  end

  test "creates a Loan account with interest_rate and term_months" do
    assert_difference "Account.count", 1 do
      result = call_tool(CreateLoanAccountTool,
        server_context: @context,
        name: "Home Mortgage",
        balance: "300000.0",
        interest_rate: "6.5",
        term_months: "360"
      )
      assert result[:success]
    end
  end

  test "returns success hash with id, name, and balance" do
    result = call_tool(CreateLoanAccountTool, server_context: @context, name: "Auto Loan", balance: "15000.0")

    assert result[:success]
    assert_not_nil result[:id]
    assert_equal "Auto Loan", result[:name]
    assert_equal 15_000.0, result[:balance].to_f
  end

  test "uses balance as initial_balance when not provided" do
    result = call_tool(CreateLoanAccountTool, server_context: @context, name: "Personal Loan", balance: "8000.0")

    assert result[:success]
    account = Account.find(result[:id])
    loan = account.accountable
    assert_equal 8_000.0, loan.initial_balance.to_f
  end

  test "uses family currency when none provided" do
    result = call_tool(CreateLoanAccountTool, server_context: @context, name: "Student Loan", balance: "20000.0")

    assert result[:success]
    created = Account.find(result[:id])
    assert_equal @family.currency, created.currency
  end

  test "stores interest_rate and term_months on loan accountable" do
    result = call_tool(CreateLoanAccountTool,
      server_context: @context,
      name: "Mortgage with Rate",
      balance: "450000.0",
      interest_rate: "7.25",
      term_months: "240"
    )

    assert result[:success]
    account = Account.find(result[:id])
    loan = account.accountable
    assert_equal 7.25, loan.interest_rate.to_f
    assert_equal 240, loan.term_months
  end
end
