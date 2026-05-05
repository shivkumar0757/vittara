require "test_helper"

class CreateTagToolTest < ActiveSupport::TestCase
  include McpToolTestHelper

  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
  end

  test "creates a tag with name and color" do
    assert_difference "@family.tags.count", 1 do
      result = call_tool(CreateTagTool, server_context: @context, name: "Vacation", color: "#4da568")
      assert result[:success]
      assert_equal "Vacation", result[:name]
      assert_equal "#4da568", result[:color]
    end
  end

  test "assigns a default color when omitted" do
    result = call_tool(CreateTagTool, server_context: @context, name: "Reimbursable")
    assert result[:success]
    assert_includes Tag::COLORS, result[:color]
  end

  test "rejects duplicate name within the family" do
    result = call_tool(CreateTagTool, server_context: @context, name: tags(:one).name)
    assert_not result[:success]
    assert result[:errors].any? { |e| e.match?(/taken|already/i) }
  end

  test "raises when write scope missing" do
    read_only = { family: @family, scopes: [ "read" ], mcp_auth: OpenStruct.new(write?: false) }
    assert_raises StandardError, /read_write/ do
      call_tool(CreateTagTool, server_context: read_only, name: "Blocked")
    end
  end
end
