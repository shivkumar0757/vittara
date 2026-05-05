require "test_helper"

class CreateCategoryToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
  end

  test "creates an expense category with defaults" do
    assert_difference "Category.count", 1 do
      result = call_tool(CreateCategoryTool, server_context: @context, name: "New Expense Category")
      assert result[:success]
      assert_equal "expense", result[:classification]
      assert_not_nil result[:id]
    end
  end

  test "creates an income category" do
    result = call_tool(CreateCategoryTool, server_context: @context, name: "Freelance Income", classification: "income",
                     color: "#4da568", lucide_icon: "briefcase")
    assert result[:success]
    assert_equal "income", result[:classification]
  end

  test "creates a subcategory under a parent" do
    parent = categories(:food_and_drink)
    result = call_tool(CreateCategoryTool, server_context: @context, name: "Groceries Sub", parent_id: parent.id)
    assert result[:success]
    assert_equal parent.id, result[:parent_id]
  end

  test "returns error when name already exists for family" do
    existing = categories(:food_and_drink)
    result = call_tool(CreateCategoryTool, server_context: @context, name: existing.name)
    assert_equal false, result[:success]
    assert result[:errors].any?
  end

  test "scopes category to current family" do
    result = call_tool(CreateCategoryTool, server_context: @context, name: "Family Scoped Category")
    assert result[:success]
    created = Category.find(result[:id])
    assert_equal @family.id, created.family_id
  end
end
