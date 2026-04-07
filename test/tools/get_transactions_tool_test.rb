require "test_helper"

class GetTransactionsToolTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    Current.stubs(:family).returns(@family)
  end

  test "returns transactions with expected structure" do
    tool = GetTransactionsTool.new
    result = tool.call

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
    tool = GetTransactionsTool.new
    result = tool.call

    family_entry_ids = @family.entries.pluck(:id)
    result.each do |txn|
      assert_includes family_entry_ids, txn[:id]
    end
  end

  test "defaults to limit of 20" do
    tool = GetTransactionsTool.new
    result = tool.call

    assert result.length <= 20
  end

  test "respects custom limit" do
    tool = GetTransactionsTool.new
    result = tool.call(limit: 1)

    assert_equal 1, result.length
  end

  test "clamps limit to minimum of 1" do
    tool = GetTransactionsTool.new
    result = tool.call(limit: 0)

    assert result.length >= 1
  end

  test "clamps limit to maximum of 100" do
    tool = GetTransactionsTool.new
    result = tool.call(limit: 999)

    assert result.length <= 100
  end

  test "filters by account_id" do
    account = accounts(:depository)
    tool = GetTransactionsTool.new
    result = tool.call(account_id: account.id)

    result.each do |txn|
      assert_equal account.name, txn[:account]
    end
  end

  test "filters by start_date" do
    start_date = 2.days.ago.to_date
    tool = GetTransactionsTool.new
    result = tool.call(start_date: start_date.iso8601)

    result.each do |txn|
      assert Date.parse(txn[:date]) >= start_date
    end
  end

  test "filters by end_date" do
    end_date = 2.days.ago.to_date
    tool = GetTransactionsTool.new
    result = tool.call(end_date: end_date.iso8601)

    result.each do |txn|
      assert Date.parse(txn[:date]) <= end_date
    end
  end

  test "returns results ordered by date descending" do
    tool = GetTransactionsTool.new
    result = tool.call

    dates = result.map { |txn| Date.parse(txn[:date]) }
    assert_equal dates.sort.reverse, dates
  end

  test "returns iso8601 formatted date" do
    tool = GetTransactionsTool.new
    result = tool.call

    result.each do |txn|
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, txn[:date])
    end
  end

  test "returns category name for categorized transaction" do
    entry = entries(:transaction)
    txn_record = entry.transaction
    category = txn_record.category

    tool = GetTransactionsTool.new
    result = tool.call
    txn_result = result.find { |t| t[:id] == entry.id }

    assert_not_nil txn_result
    assert_equal category.name, txn_result[:category]
  end
end
