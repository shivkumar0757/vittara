# frozen_string_literal: true

class Settings::ApiKeysController < ApplicationController
  layout "settings"

  before_action :set_api_key, only: [ :show, :destroy ]

  def show
    @current_api_key = @api_key
    @mcp_key = Current.user.api_keys.active.find_by(source: "mcp")
  end

  def create_mcp_token
    existing = Current.user.api_keys.active.find_by(source: "mcp")
    return redirect_to settings_api_key_path if existing

    plain_key = ApiKey.generate_secure_key
    api_key = Current.user.api_keys.build(
      name: "MCP Token",
      source: "mcp",
      scopes: [ "read_write" ],
      key: plain_key
    )

    if api_key.save
      @mcp_key = api_key
      @current_api_key = Current.user.api_keys.active.find_by(source: "web")
      render :show
    else
      flash[:alert] = "Failed to generate MCP token: #{api_key.errors.full_messages.to_sentence}"
      redirect_to settings_api_key_path
    end
  end

  def destroy_mcp_token
    mcp_key = Current.user.api_keys.active.find_by(source: "mcp")
    if mcp_key&.revoke!
      flash[:notice] = "MCP token revoked"
    else
      flash[:alert] = "No active MCP token found"
    end
    redirect_to settings_api_key_path
  end

  def new
    # Allow regeneration by not redirecting if user explicitly wants to create a new key
    # Only redirect if user stumbles onto new page without explicit intent
    redirect_to settings_api_key_path if Current.user.api_keys.active.where(source: "web").exists? && !params[:regenerate]
    @api_key = ApiKey.new
  end

  def create
    @plain_key = ApiKey.generate_secure_key
    @api_key = Current.user.api_keys.build(api_key_params)
    @api_key.key = @plain_key

    # Temporarily revoke existing web keys for validation to pass
    existing_keys = Current.user.api_keys.active.where(source: "web")
    existing_keys.each { |key| key.update_column(:revoked_at, Time.current) }

    if @api_key.save
      flash[:notice] = "Your API key has been created successfully"
      redirect_to settings_api_key_path
    else
      # Restore existing keys if new key creation failed
      existing_keys.each { |key| key.update_column(:revoked_at, nil) }
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @api_key&.revoke!
      flash[:notice] = "API key has been revoked successfully"
    else
      flash[:alert] = "Failed to revoke API key"
    end
    redirect_to settings_api_key_path
  end

  private

    def set_api_key
      @api_key = Current.user.api_keys.active.find_by(source: "web")
    end

    def api_key_params
      # Convert single scope value to array for storage
      permitted_params = params.require(:api_key).permit(:name, :scopes)
      if permitted_params[:scopes].present?
        permitted_params[:scopes] = [ permitted_params[:scopes] ]
      end
      permitted_params
    end
end
