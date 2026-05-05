class McpController < ApplicationController
  skip_authentication
  skip_before_action :verify_authenticity_token

  def handle
    return head(:method_not_allowed) if request.get?
    return head(:accepted) if params[:method] == "notifications/initialized"

    auth = authenticate_mcp_request
    render json: mcp_server(auth).handle_json(request.raw_post)
  end

  private

    def mcp_server(auth)
      MCP::Server.new(
        name: "vittara",
        version: "1.0.0",
        tools: MCP::Tool.descendants.reject { |t| t.name == "ApplicationTool" }.uniq(&:name),
        server_context: {
          family: auth&.user&.family,
          scopes: auth&.scopes || [],
          mcp_auth: auth
        }
      )
    end

    def authenticate_mcp_request
      token = request.headers["Authorization"]&.split(" ", 2)&.last
      auth = McpAuth.resolve(token)
      setup_current_context(auth.user) if auth
      auth
    end

    def setup_current_context(user)
      session = user.sessions.first ||
        user.sessions.build(user_agent: "MCP Client", ip_address: "0.0.0.0")
      Current.session = session
    end
end
