require "test_helper"

class ApplicationToolTest < ActiveSupport::TestCase
  include McpToolTestHelper
  def setup
    @user = users(:family_admin)
    @family = @user.family
  end

  # --- Tool registration ---

  test "all tools are registered as MCP::Tool descendants" do
    Rails.application.eager_load!
    descendants = MCP::Tool.descendants
    assert_includes descendants, GetAccountsTool
    assert_includes descendants, CreateTransactionTool
    assert_operator descendants.length, :>=, 11
  end

  # --- Auth helpers ---

  test "current_family returns family from server_context" do
    context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
    result = call_tool(GetAccountsTool, server_context: context)
    assert result.is_a?(Array)
  end

  test "current_family raises when no family in server_context" do
    context = { family: nil, scopes: [], mcp_auth: nil }
    assert_raises(StandardError) { GetAccountsTool.call(server_context: context) }
  end

  test "require_write_access passes for read_write scope" do
    context = { family: @family, scopes: [ "read_write" ], mcp_auth: OpenStruct.new(write?: true) }
    assert_nothing_raised { call_tool(CreateCategoryTool, server_context: context, name: "Test Category") }
  end

  test "require_write_access fails for read-only scope" do
    context = { family: @family, scopes: [ "read" ], mcp_auth: OpenStruct.new(write?: false) }
    assert_raises(StandardError) { CreateCategoryTool.call(server_context: context, name: "Test Category") }
  end

  # --- McpAuth integration ---

  test "McpAuth resolves valid ApiKey token" do
    @user.api_keys.where(source: "mcp").destroy_all
    ApiKey.create!(user: @user, name: "MCP Token", key: "test_token_123", scopes: [ "read_write" ], source: "mcp")

    auth = McpAuth.resolve("test_token_123")
    assert_not_nil auth
    assert_equal @user, auth.user
    assert auth.write?
  end

  test "McpAuth resolves valid Doorkeeper OAuth token" do
    oauth_app = Doorkeeper::Application.create!(
      name: "Test Connector",
      redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      scopes: "read_write",
      confidential: true
    )
    access_token = Doorkeeper::AccessToken.create!(
      application: oauth_app,
      resource_owner_id: @user.id,
      scopes: "read_write",
      expires_in: 1.hour.to_i
    )

    auth = McpAuth.resolve(access_token.plaintext_token)
    assert_not_nil auth
    assert_equal @user, auth.user
    assert auth.write?
  end

  test "McpAuth returns nil for invalid token" do
    assert_nil McpAuth.resolve("invalid_token")
  end
end
