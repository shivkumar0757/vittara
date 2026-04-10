class ApplicationTool < FastMcp::Tool
  UnauthorizedError = Class.new(StandardError)

  authorize do |_arguments|
    authenticate_mcp_token!
  end

  private

    def authenticate_mcp_token!
      token = extract_bearer_token
      @mcp_auth = McpAuth.resolve(token)

      unless @mcp_auth
        raise UnauthorizedError, "Invalid or missing MCP token"
      end

      setup_current_context(@mcp_auth.user)
      @mcp_auth.touch_last_used!
    end

    def extract_bearer_token
      # fast-mcp lowercases header keys: HTTP_AUTHORIZATION → "authorization"
      auth_header = headers["authorization"] || headers["AUTHORIZATION"]
      return nil unless auth_header&.start_with?("Bearer ")

      auth_header.split(" ", 2).last.presence
    end

    def setup_current_context(user)
      session = user.sessions.first ||
        user.sessions.build(user_agent: "MCP Client", ip_address: "0.0.0.0")
      Current.session = session
    end

    def current_family
      Current.family
    end

    def require_write_access!
      unless @mcp_auth&.write?
        raise UnauthorizedError, "Write access requires read_write scope"
      end
    end
end
