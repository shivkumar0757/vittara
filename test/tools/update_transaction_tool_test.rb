require "test_helper"

class UpdateTransactionToolTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)
    @entry = entries(:transaction)
    Current.stubs(:family).returns(@family)
  end

  def build_tool
    tool = UpdateTransactionTool.new
    tool.stubs(:require_write_access!)
    tool
  end

  # 1. Updates name
  test "updates entry name" do
    tool = build_tool

    result = tool.call(entry_id: @entry.id, name: "Updated Coffee")

    assert result[:success]
    assert_equal "Updated Coffee", result[:name]
    assert_equal "Updated Coffee", @entry.reload.name
  end

  # 2. Updates date
  test "updates entry date" do
    tool = build_tool

    result = tool.call(entry_id: @entry.id, date: "2026-03-01")

    assert result[:success]
    assert_equal "2026-03-01", result[:date]
    assert_equal Date.new(2026, 3, 1), @entry.reload.date
  end

  # 3. Updates category
  test "updates transaction category" do
    tool = build_tool
    category = categories(:income)

    result = tool.call(entry_id: @entry.id, category_id: category.id)

    assert result[:success]
    assert_equal category.id, @entry.reload.transaction.category_id
  end

  # 4. Scopes to family (raises RecordNotFound for entry from another family)
  test "raises RecordNotFound for entry outside current family" do
    other_family = families(:empty)
    Current.stubs(:family).returns(other_family)

    tool = build_tool

    assert_raises ActiveRecord::RecordNotFound do
      tool.call(entry_id: @entry.id, name: "Hacked")
    end
  end

  # 5. Returns success hash with id/name/date
  test "returns success hash with required keys" do
    tool = build_tool

    result = tool.call(entry_id: @entry.id, name: "New Name")

    assert result[:success]
    assert_equal @entry.id, result[:id]
    assert_equal "New Name", result[:name]
    assert_match(/\A\d{4}-\d{2}-\d{2}\z/, result[:date])
  end

  # Extra: partial update — only provided fields change
  test "does not change name when only date is updated" do
    tool = build_tool
    original_name = @entry.name

    result = tool.call(entry_id: @entry.id, date: "2026-04-01")

    assert result[:success]
    assert_equal original_name, @entry.reload.name
  end

  # Extra: notes update
  test "updates notes" do
    tool = build_tool

    result = tool.call(entry_id: @entry.id, notes: "Important expense")

    assert result[:success]
    assert_equal "Important expense", @entry.reload.notes
  end
end
