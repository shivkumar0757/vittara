require "test_helper"

class CreateTransferToolTest < ActiveSupport::TestCase
  include McpToolTestHelper

  def setup
    @family = families(:dylan_family)
    @from = accounts(:depository)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
  end

  test "creates a regular funds movement transfer" do
    to = @family.accounts.create!(
      name: "Savings",
      balance: 1000,
      currency: "USD",
      accountable: Depository.new
    )

    result = call_tool(CreateTransferTool,
      server_context: @context,
      from_account_id: @from.id,
      to_account_id: to.id,
      amount: "100.00",
      date: Date.current.iso8601
    )

    assert result[:success]
    assert_equal "transfer", result[:transfer_type]
    assert_in_delta 100.0, result[:amount].to_f, 0.001
  end

  test "destination credit card classifies as liability_payment" do
    to = accounts(:credit_card)

    result = call_tool(CreateTransferTool,
      server_context: @context,
      from_account_id: @from.id,
      to_account_id: to.id,
      amount: "250.00",
      date: Date.current.iso8601
    )

    assert result[:success]
    assert_equal "liability_payment", result[:transfer_type]
  end

  test "destination loan classifies as loan_payment" do
    to = accounts(:loan)

    result = call_tool(CreateTransferTool,
      server_context: @context,
      from_account_id: @from.id,
      to_account_id: to.id,
      amount: "500.00",
      date: Date.current.iso8601
    )

    assert result[:success]
    assert_equal "loan_payment", result[:transfer_type]
  end

  test "rejects transfer to the same account" do
    result = call_tool(CreateTransferTool,
      server_context: @context,
      from_account_id: @from.id,
      to_account_id: @from.id,
      amount: "10.00",
      date: Date.current.iso8601
    )

    assert_not result[:success]
    assert result[:errors].any? { |e| e.match?(/different accounts/i) }
  end

  test "raises when write scope missing" do
    read_only_context = { family: @family, scopes: [ "read" ], mcp_auth: OpenStruct.new(write?: false) }

    assert_raises StandardError, /read_write/ do
      call_tool(CreateTransferTool,
        server_context: read_only_context,
        from_account_id: @from.id,
        to_account_id: accounts(:credit_card).id,
        amount: "10.00",
        date: Date.current.iso8601
      )
    end
  end
end
