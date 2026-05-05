require "test_helper"

class UpdateTransactionToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @family = families(:dylan_family)
    @entry = entries(:transaction)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
  end

  # 1. Updates name
  test "updates entry name" do
    result = call_tool(UpdateTransactionTool, server_context: @context, entry_id: @entry.id, name: "Updated Coffee")

    assert result[:success]
    assert_equal "Updated Coffee", result[:name]
    assert_equal "Updated Coffee", @entry.reload.name
  end

  # 2. Updates date
  test "updates entry date" do
    result = call_tool(UpdateTransactionTool, server_context: @context, entry_id: @entry.id, date: "2026-03-01")

    assert result[:success]
    assert_equal "2026-03-01", result[:date]
    assert_equal Date.new(2026, 3, 1), @entry.reload.date
  end

  # 3. Updates category
  test "updates transaction category" do
    category = categories(:income)

    result = call_tool(UpdateTransactionTool, server_context: @context, entry_id: @entry.id, category_id: category.id)

    assert result[:success]
    assert_equal category.id, @entry.reload.transaction.category_id
  end

  # 4. Scopes to family (raises RecordNotFound for entry from another family)
  test "raises RecordNotFound for entry outside current family" do
    other_family = families(:empty)
    other_context = { family: other_family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }

    assert_raises ActiveRecord::RecordNotFound do
      call_tool(UpdateTransactionTool, server_context: other_context, entry_id: @entry.id, name: "Hacked")
    end
  end

  # 5. Returns success hash with id/name/date
  test "returns success hash with required keys" do
    result = call_tool(UpdateTransactionTool, server_context: @context, entry_id: @entry.id, name: "New Name")

    assert result[:success]
    assert_equal @entry.id, result[:id]
    assert_equal "New Name", result[:name]
    assert_match(/\A\d{4}-\d{2}-\d{2}\z/, result[:date])
  end

  # Extra: partial update — only provided fields change
  test "does not change name when only date is updated" do
    original_name = @entry.name

    result = call_tool(UpdateTransactionTool, server_context: @context, entry_id: @entry.id, date: "2026-04-01")

    assert result[:success]
    assert_equal original_name, @entry.reload.name
  end

  # Extra: notes update
  test "updates notes" do
    result = call_tool(UpdateTransactionTool, server_context: @context, entry_id: @entry.id, notes: "Important expense")

    assert result[:success]
    assert_equal "Important expense", @entry.reload.notes
  end

  # Tags: replace set
  test "tag_ids replaces the full tag set" do
    tag_a = tags(:one)
    tag_b = tags(:two)
    @entry.transaction.update!(tag_ids: [ tag_a.id ])

    result = call_tool(UpdateTransactionTool, server_context: @context, entry_id: @entry.id, tag_ids: [ tag_b.id ])

    assert result[:success]
    assert_equal [ tag_b.id ], @entry.reload.transaction.tag_ids
  end

  # Tags: empty array clears tags
  test "tag_ids: [] clears all tags" do
    @entry.transaction.update!(tag_ids: [ tags(:one).id ])

    result = call_tool(UpdateTransactionTool, server_context: @context, entry_id: @entry.id, tag_ids: [])

    assert result[:success]
    assert_empty @entry.reload.transaction.tags
  end
end
