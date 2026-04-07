require "test_helper"

class GetCategoriesToolTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)
    Current.stubs(:family).returns(@family)
  end

  test "returns all categories for the family" do
    tool = GetCategoriesTool.new
    result = tool.call

    assert_instance_of Array, result
    assert result.length >= 1
  end

  test "returns categories with expected structure" do
    tool = GetCategoriesTool.new
    result = tool.call

    result.each do |cat|
      assert cat.key?(:id)
      assert cat.key?(:name)
      assert cat.key?(:classification)
      assert cat.key?(:parent_id)
    end
  end

  test "returns categories scoped to current family" do
    tool = GetCategoriesTool.new
    result = tool.call

    family_category_ids = @family.categories.pluck(:id)
    result_ids = result.map { |c| c[:id] }

    result_ids.each do |id|
      assert_includes family_category_ids, id, "Category #{id} does not belong to the family"
    end
  end

  test "does not return categories from other families" do
    other_family = families(:empty)
    other_category = categories(:one) # belongs to :empty family

    tool = GetCategoriesTool.new
    result = tool.call

    result_ids = result.map { |c| c[:id] }
    assert_not_includes result_ids, other_category.id
  end

  test "returns categories in alphabetical order" do
    tool = GetCategoriesTool.new
    result = tool.call

    names = result.map { |c| c[:name] }
    assert_equal names.sort, names
  end

  test "returns correct values for a known category" do
    food = categories(:food_and_drink)
    tool = GetCategoriesTool.new
    result = tool.call

    food_result = result.find { |c| c[:id] == food.id }
    assert_not_nil food_result
    assert_equal food.name, food_result[:name]
    assert_equal food.classification, food_result[:classification]
    assert_nil food_result[:parent_id]
  end

  test "includes subcategory with correct parent_id" do
    sub = categories(:subcategory)
    parent = categories(:food_and_drink)

    tool = GetCategoriesTool.new
    result = tool.call

    sub_result = result.find { |c| c[:id] == sub.id }
    assert_not_nil sub_result
    assert_equal parent.id, sub_result[:parent_id]
  end
end
