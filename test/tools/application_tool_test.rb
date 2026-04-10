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

  # --- ApiKey auth tests ---

  test "authenticates valid mcp token and sets Current.session" do
    tool = build_tool_with_bearer("mcp_test_token_abc123")

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
    tool = build_tool_with_bearer("wrong_token")

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end

  test "raises unauthorized for non-mcp api key" do
    @user.api_keys.where(source: "web").destroy_all
    ApiKey.create!(user: @user, name: "Web Key", key: "web_token_xyz789", scopes: [ "read_write" ], source: "web")

    tool = build_tool_with_bearer("web_token_xyz789")

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end

  test "raises unauthorized for revoked mcp token" do
    @mcp_key.revoke!
    tool = build_tool_with_bearer("mcp_test_token_abc123")

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end

  # --- OAuth (Doorkeeper) auth tests ---

  test "authenticates valid Doorkeeper OAuth token" do
    access_token = create_oauth_token(scopes: "read_write")
    tool = build_tool_with_bearer(access_token.plaintext_token)

    assert_nothing_raised { tool.send(:authenticate_mcp_token!) }
    assert_not_nil Current.session
    assert_equal @user, Current.user
  end

  test "raises unauthorized for expired Doorkeeper token" do
    access_token = create_oauth_token(scopes: "read_write", expires_in: 1.hour.to_i)
    tool = build_tool_with_bearer(access_token.plaintext_token)

    travel 2.hours
    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end

  test "raises unauthorized for revoked Doorkeeper token" do
    access_token = create_oauth_token(scopes: "read_write")
    access_token.revoke

    tool = build_tool_with_bearer(access_token.plaintext_token)

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:authenticate_mcp_token!) }
  end

  test "require_write_access passes for read_write OAuth token" do
    access_token = create_oauth_token(scopes: "read_write")
    tool = build_tool_with_bearer(access_token.plaintext_token)
    tool.send(:authenticate_mcp_token!)

    assert_nothing_raised { tool.send(:require_write_access!) }
  end

  test "require_write_access fails for read-only OAuth token" do
    access_token = create_oauth_token(scopes: "read")
    tool = build_tool_with_bearer(access_token.plaintext_token)
    tool.send(:authenticate_mcp_token!)

    assert_raises(ApplicationTool::UnauthorizedError) { tool.send(:require_write_access!) }
  end

  private

    def build_tool_with_bearer(token)
      tool = ApplicationTool.new
      tool.stubs(:headers).returns({ "AUTHORIZATION" => "Bearer #{token}" })
      tool
    end

    def create_oauth_token(scopes:, expires_in: 1.hour.to_i)
      oauth_app = Doorkeeper::Application.create!(
        name: "Test Connector",
        redirect_uri: "https://claude.ai/api/mcp/auth_callback",
        scopes: scopes,
        confidential: true
      )

      Doorkeeper::AccessToken.create!(
        application: oauth_app,
        resource_owner_id: @user.id,
        scopes: scopes,
        expires_in: expires_in
      )
    end
end
