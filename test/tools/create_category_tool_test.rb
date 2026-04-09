require "test_helper"

class CreateCategoryToolTest < ActiveSupport::TestCase
  def setup
    Current.stubs(:family).returns(families(:dylan_family))
  end

  def build_tool
    tool = CreateCategoryTool.new
    tool.stubs(:require_write_access!)
    tool
  end

  test "creates an expense category with defaults" do
    tool = build_tool
    assert_difference "Category.count", 1 do
      result = tool.call(name: "New Expense Category")
      assert result[:success]
      assert_equal "expense", result[:classification]
      assert_not_nil result[:id]
    end
  end

  test "creates an income category" do
    tool = build_tool
    result = tool.call(name: "Freelance Income", classification: "income",
                       color: "#4da568", lucide_icon: "briefcase")
    assert result[:success]
    assert_equal "income", result[:classification]
  end

  test "creates a subcategory under a parent" do
    parent = categories(:food_and_drink)
    tool = build_tool
    result = tool.call(name: "Groceries Sub", parent_id: parent.id)
    assert result[:success]
    assert_equal parent.id, result[:parent_id]
  end

  test "returns error when name already exists for family" do
    existing = categories(:food_and_drink)
    tool = build_tool
    result = tool.call(name: existing.name)
    assert_equal false, result[:success]
    assert result[:errors].any?
  end

  test "scopes category to current family" do
    tool = build_tool
    result = tool.call(name: "Family Scoped Category")
    assert result[:success]
    created = Category.find(result[:id])
    assert_equal families(:dylan_family).id, created.family_id
  end
end
