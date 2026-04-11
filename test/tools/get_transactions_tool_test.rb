require "test_helper"

class GetTransactionsToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
  end

  test "returns transactions with expected structure" do
    result = call_tool(GetTransactionsTool, server_context: @context)

    assert_instance_of Array, result
    result.each do |txn|
      assert txn.key?(:id)
      assert txn.key?(:date)
      assert txn.key?(:name)
      assert txn.key?(:amount)
      assert txn.key?(:currency)
      assert txn.key?(:category)
      assert txn.key?(:account)
    end
  end

  test "returns transactions scoped to current family" do
    result = call_tool(GetTransactionsTool, server_context: @context)

    family_entry_ids = @family.entries.pluck(:id)
    result.each do |txn|
      assert_includes family_entry_ids, txn[:id]
    end
  end

  test "defaults to limit of 20" do
    result = call_tool(GetTransactionsTool, server_context: @context)

    assert result.length <= 20
  end

  test "respects custom limit" do
    result = call_tool(GetTransactionsTool, server_context: @context, limit: "1")

    assert_equal 1, result.length
  end

  test "clamps limit to minimum of 1" do
    result = call_tool(GetTransactionsTool, server_context: @context, limit: "0")

    assert result.length >= 1
  end

  test "clamps limit to maximum of 100" do
    result = call_tool(GetTransactionsTool, server_context: @context, limit: "999")

    assert result.length <= 100
  end

  test "filters by account_id" do
    account = accounts(:depository)
    result = call_tool(GetTransactionsTool, server_context: @context, account_id: account.id)

    result.each do |txn|
      assert_equal account.name, txn[:account]
    end
  end

  test "filters by start_date" do
    start_date = 2.days.ago.to_date
    result = call_tool(GetTransactionsTool, server_context: @context, start_date: start_date.iso8601)

    result.each do |txn|
      assert Date.parse(txn[:date]) >= start_date
    end
  end

  test "filters by end_date" do
    end_date = 2.days.ago.to_date
    result = call_tool(GetTransactionsTool, server_context: @context, end_date: end_date.iso8601)

    result.each do |txn|
      assert Date.parse(txn[:date]) <= end_date
    end
  end

  test "returns results ordered by date descending" do
    result = call_tool(GetTransactionsTool, server_context: @context)

    dates = result.map { |txn| Date.parse(txn[:date]) }
    assert_equal dates.sort.reverse, dates
  end

  test "returns iso8601 formatted date" do
    result = call_tool(GetTransactionsTool, server_context: @context)

    result.each do |txn|
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, txn[:date])
    end
  end

  test "returns category name for categorized transaction" do
    entry = entries(:transaction)
    txn_record = entry.transaction
    category = txn_record.category

    result = call_tool(GetTransactionsTool, server_context: @context)
    txn_result = result.find { |t| t[:id] == entry.id }

    assert_not_nil txn_result
    assert_equal category.name, txn_result[:category]
  end
end
