require "test_helper"

class GetTagsToolTest < ActiveSupport::TestCase
  include McpToolTestHelper

  def setup
    @family = families(:dylan_family)
    @context = { family: @family, scopes: [ "read" ], mcp_auth: OpenStruct.new(write?: false) }
  end

  test "returns tags for the current family only" do
    result = call_tool(GetTagsTool, server_context: @context)

    names = result.map { |t| t[:name] }
    assert_includes names, tags(:one).name
    assert_includes names, tags(:two).name
    assert_not_includes names, tags(:three).name # belongs to a different family
  end

  test "returns id, name, and color for each tag" do
    result = call_tool(GetTagsTool, server_context: @context)
    sample = result.first
    assert sample.key?(:id)
    assert sample.key?(:name)
    assert sample.key?(:color)
  end
end
