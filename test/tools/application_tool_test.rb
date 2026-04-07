require "test_helper"

class ApplicationToolTest < ActiveSupport::TestCase
  def setup
    @user = users(:family_admin)
    @user.api_keys.where(source: "mcp").destroy_all

    @mcp_key = ApiKey.create!(
      user: @user,
      name: "MCP Token",
      key: "mcp_test_token_abc123",
      scopes: [ "read_write" ],
      source: "mcp"
    )
  end

  test "authenticates valid mcp token and sets Current.session" do
    tool = ApplicationTool.new
    tool.stubs(:headers).returns({ "AUTHORIZATION" => "Bearer mcp_test_token_abc123" })

    assert_nothing_raised { tool.send(:authenticate_mcp_token!) }
    assert_not_nil Current.session
    assert_equal @user, Current.user
  end

  test "raises unauthorized for missing token" do
    tool = ApplicationTool.new
    tool.stubs(:headers).returns({})

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end

  test "raises unauthorized for invalid token" do
    tool = ApplicationTool.new
    tool.stubs(:headers).returns({ "AUTHORIZATION" => "Bearer wrong_token" })

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end

  test "raises unauthorized for non-mcp api key" do
    @user.api_keys.where(source: "web").destroy_all
    web_key = ApiKey.create!(
      user: @user,
      name: "Web Key",
      key: "web_token_xyz789",
      scopes: [ "read_write" ],
      source: "web"
    )

    tool = ApplicationTool.new
    tool.stubs(:headers).returns({ "AUTHORIZATION" => "Bearer web_token_xyz789" })

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end

  test "raises unauthorized for revoked mcp token" do
    @mcp_key.revoke!

    tool = ApplicationTool.new
    tool.stubs(:headers).returns({ "AUTHORIZATION" => "Bearer mcp_test_token_abc123" })

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end
end
