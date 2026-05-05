require "test_helper"

class CreateTransactionToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @family = families(:dylan_family)
    @account = accounts(:depository)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
  end

  test "creates an entry with correct fields" do
    result = nil

    assert_difference "Entry.count", 1 do
      result = call_tool(CreateTransactionTool,
        server_context: @context,
        account_id: @account.id,
        amount: "25.50",
        date: "2026-01-15",
        name: "Coffee Shop"
      )
      assert result[:success]
    end

    entry = Entry.find(result[:id])
    assert_equal "Coffee Shop", entry.name
    assert_equal Date.new(2026, 1, 15), entry.date
    assert_in_delta 25.50, entry.amount.to_f, 0.001
    assert_equal @account.id, entry.account_id
  end

  test "expense nature forces positive amount" do
    result = call_tool(CreateTransactionTool,
      server_context: @context,
      account_id: @account.id,
      amount: "-50.0",
      date: "2026-01-15",
      name: "Grocery Store",
      nature: "expense"
    )

    assert result[:success]
    assert_operator result[:amount].to_f, :>, 0
  end

  test "income nature forces negative amount" do
    result = call_tool(CreateTransactionTool,
      server_context: @context,
      account_id: @account.id,
      amount: "100.0",
      date: "2026-01-15",
      name: "Salary",
      nature: "income"
    )

    assert result[:success]
    assert_operator result[:amount].to_f, :<, 0
  end

  test "no nature uses amount as provided" do
    result = call_tool(CreateTransactionTool,
      server_context: @context,
      account_id: @account.id,
      amount: "-75.0",
      date: "2026-01-15",
      name: "Refund"
    )

    assert result[:success]
    assert_in_delta(-75.0, result[:amount].to_f, 0.001)
  end

  test "returns success hash with required keys" do
    result = call_tool(CreateTransactionTool,
      server_context: @context,
      account_id: @account.id,
      amount: "12.99",
      date: "2026-02-20",
      name: "Netflix"
    )

    assert result[:success]
    assert_not_nil result[:id]
    assert_equal "Netflix", result[:name]
    assert_in_delta 12.99, result[:amount].to_f, 0.001
    assert_equal "2026-02-20", result[:date]
  end

  test "raises RecordNotFound for unknown account_id" do
    assert_raises ActiveRecord::RecordNotFound do
      call_tool(CreateTransactionTool,
        server_context: @context,
        account_id: "00000000-0000-0000-0000-000000000000",
        amount: "10.0",
        date: "2026-01-15",
        name: "Test"
      )
    end
  end

  test "inflow nature forces negative amount" do
    result = call_tool(CreateTransactionTool,
      server_context: @context,
      account_id: @account.id,
      amount: "200.0",
      date: "2026-01-15",
      name: "Transfer In",
      nature: "inflow"
    )

    assert result[:success]
    assert_operator result[:amount].to_f, :<, 0
  end

  test "outflow nature forces positive amount" do
    result = call_tool(CreateTransactionTool,
      server_context: @context,
      account_id: @account.id,
      amount: "-30.0",
      date: "2026-01-15",
      name: "Transfer Out",
      nature: "outflow"
    )

    assert result[:success]
    assert_operator result[:amount].to_f, :>, 0
  end

  test "persists category when category_id provided" do
    category = categories(:food_and_drink)

    result = call_tool(CreateTransactionTool,
      server_context: @context,
      account_id: @account.id,
      amount: "8.50",
      date: "2026-01-15",
      name: "Lunch",
      category_id: category.id
    )

    assert result[:success]
    entry = Entry.find(result[:id])
    assert_equal category.id, entry.transaction.category_id
  end

  test "persists tag_ids when provided" do
    tag = tags(:one)

    result = call_tool(CreateTransactionTool,
      server_context: @context,
      account_id: @account.id,
      amount: "50.00",
      date: "2026-01-15",
      name: "Hotel",
      tag_ids: [ tag.id ]
    )

    assert result[:success]
    entry = Entry.find(result[:id])
    assert_equal [ tag.id ], entry.transaction.tag_ids
  end
end
