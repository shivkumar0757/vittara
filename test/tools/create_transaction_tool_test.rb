require "test_helper"

class CreateTransactionToolTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @account = accounts(:depository)
    Current.stubs(:family).returns(@family)
  end

  # Stub require_write_access! so tests focus on business logic, not auth
  def build_tool
    tool = CreateTransactionTool.new
    tool.stubs(:require_write_access!)
    tool
  end

  # 1. Creates an entry with correct fields
  test "creates an entry with correct fields" do
    tool = build_tool
    result = nil

    assert_difference "Entry.count", 1 do
      result = tool.call(
        account_id: @account.id,
        amount: 25.50,
        date: "2026-01-15",
        name: "Coffee Shop"
      )
      assert result[:success]
    end

    entry = Entry.find(result[:id])
    assert_equal "Coffee Shop", entry.name
    assert_equal Date.new(2026, 1, 15), entry.date
    assert_in_delta 25.50, entry.amount, 0.001
    assert_equal @account.id, entry.account_id
  end

  # 2. expense nature → positive amount
  test "expense nature forces positive amount" do
    tool = build_tool

    result = tool.call(
      account_id: @account.id,
      amount: -50.0,
      date: "2026-01-15",
      name: "Grocery Store",
      nature: "expense"
    )

    assert result[:success]
    assert_operator result[:amount], :>, 0, "Expense should have positive amount"
  end

  # 3. income nature → negative amount
  test "income nature forces negative amount" do
    tool = build_tool

    result = tool.call(
      account_id: @account.id,
      amount: 100.0,
      date: "2026-01-15",
      name: "Salary",
      nature: "income"
    )

    assert result[:success]
    assert_operator result[:amount], :<, 0, "Income should have negative amount"
  end

  # 4. No nature → amount used as-is
  test "no nature uses amount as provided" do
    tool = build_tool

    result = tool.call(
      account_id: @account.id,
      amount: -75.0,
      date: "2026-01-15",
      name: "Refund"
    )

    assert result[:success]
    assert_in_delta(-75.0, result[:amount], 0.001)
  end

  # 5. Returns success hash with id/name/amount/date
  test "returns success hash with required keys" do
    tool = build_tool

    result = tool.call(
      account_id: @account.id,
      amount: 12.99,
      date: "2026-02-20",
      name: "Netflix"
    )

    assert result[:success]
    assert_not_nil result[:id]
    assert_equal "Netflix", result[:name]
    assert_in_delta 12.99, result[:amount], 0.001
    assert_equal "2026-02-20", result[:date]
  end

  # 6. Returns failure hash when account not found
  test "raises RecordNotFound for unknown account_id" do
    tool = build_tool

    assert_raises ActiveRecord::RecordNotFound do
      tool.call(
        account_id: 0,
        amount: 10.0,
        date: "2026-01-15",
        name: "Test"
      )
    end
  end

  # Extra: inflow nature also produces negative amount
  test "inflow nature forces negative amount" do
    tool = build_tool

    result = tool.call(
      account_id: @account.id,
      amount: 200.0,
      date: "2026-01-15",
      name: "Transfer In",
      nature: "inflow"
    )

    assert result[:success]
    assert_operator result[:amount], :<, 0
  end

  # Extra: outflow nature forces positive amount
  test "outflow nature forces positive amount" do
    tool = build_tool

    result = tool.call(
      account_id: @account.id,
      amount: -30.0,
      date: "2026-01-15",
      name: "Transfer Out",
      nature: "outflow"
    )

    assert result[:success]
    assert_operator result[:amount], :>, 0
  end

  # Extra: category_id is persisted when provided
  test "persists category when category_id provided" do
    tool = build_tool
    category = categories(:food_and_drink)

    result = tool.call(
      account_id: @account.id,
      amount: 8.50,
      date: "2026-01-15",
      name: "Lunch",
      category_id: category.id
    )

    assert result[:success]
    entry = Entry.find(result[:id])
    assert_equal category.id, entry.transaction.category_id
  end
end
