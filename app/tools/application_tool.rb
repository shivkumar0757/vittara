class ApplicationTool < MCP::Tool
  # Unwrap MCP::Tool::Response back to parsed data (for tests)
  def self.unwrap(response)
    JSON.parse(response.to_h[:content].first[:text], symbolize_names: true)
  end

  class << self
    private

      def current_family(server_context)
        family = server_context[:family]
        raise StandardError, "Unauthorized — invalid or missing MCP token" unless family
        family
      end

      def require_write_access!(server_context)
        unless server_context[:mcp_auth]&.write?
          raise StandardError, "Write access requires read_write scope"
        end
      end

      def text_response(data)
        MCP::Tool::Response.new([ { type: "text", text: data.to_json } ])
      end
  end
end
