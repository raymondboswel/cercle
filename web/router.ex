defmodule CercleApi.Router do
  use CercleApi.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :basic_auth do
    plug BasicAuth, use_config: {:cercleApi, :basic_auth}
  end

  pipeline :browser_json do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :api_auth do
    plug ExOauth2Provider.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser_auth do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :require_login do
    plug Guardian.Plug.EnsureAuthenticated, handler: CercleApi.GuardianErrorHandler
    plug CercleApi.Plug.CurrentUser
  end

  pipeline :already_authenticated do
    plug Guardian.Plug.EnsureNotAuthenticated, handler: CercleApi.GuardianAlreadyAuthenticatedHandler
  end

  scope "/", CercleApi do
    pipe_through [:browser, :browser_auth, :already_authenticated]
    get "/", PageController, :index
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create

    get "/forget-password", PasswordController, :forget_password
    post "/reset-password", PasswordController, :reset_password
    get "/password/reset/:password_reset_code/confirm", PasswordController, :confirm
    post "/password/reset/:password_reset_code/confirm", PasswordController, :confirm_submit
    get "/register/:register_values/join/", RegistrationController, :accept_team_invitation
    get "/register/:register_values/join/:useless_gmail", RegistrationController, :accept_team_invitation
  end

  scope "/", CercleApi do
    pipe_through [:browser, :browser_auth, :require_login]

    get "/logout", SessionController, :delete
    get "/settings/profile_edit", SettingsController, :profile_edit
    put "/settings/profile_update", SettingsController, :profile_update
    get "/settings/company_edit", SettingsController, :company_edit
    put "/settings/company_update", SettingsController, :company_update
    get "/settings/team_edit", SettingsController, :team_edit
    delete "/settings/remove_team_member/:user_id", SettingsController, :remove_team_member
    put "/settings/team_update", SettingsController, :team_update
    get "/settings/fields_edit", SettingsController, :fields_edit
    put "/settings/fields_update", SettingsController, :fields_update
    post "/settings/team_invitation", SettingsController, :team_invitation
    get "/settings/tags_edit", SettingsController, :tags_edit
    get "/settings/api_key", SettingsController, :api_key
    get "/settings/webhooks", SettingsController, :webhooks

    get "/contact", ContactController, :index
    get "/contact/new", ContactController, :new
    get "/contact/:id", ContactController, :show
    get "/contact/:id/card/:card_id", ContactController, :show

    resources "/board", BoardController
    get "/activity", ActivityController, :index

    get "/import", ImportController, :import
    post "/import_data", ImportController, :import_data
    post "/view_uploaded_data", ImportController, :view_uploaded_data
    post "/create_nested_data", ImportController, :create_nested_data

  end

  scope "/", CercleApi do
    pipe_through [:api, :api_auth]

    post "/api/v2/register", APIV2.UserController, :create
    post "/api/v2/login", APIV2.SessionController, :create

    post "/api/v2/contact/export", APIV2.ContactExportController, :export
    resources "/api/v2/contact", APIV2.ContactController
    put "/api/v2/contact/:id/update_tags", APIV2.ContactController, :update_tags
    put "/api/v2/contact/:id/utags", APIV2.ContactController, :utags
    delete "/api/v2/contact/multiple/delete", APIV2.ContactController, :multiple_delete

    resources "/api/v2/tag", APIV2.TagController, only: [:index, :create]

    resources "/api/v2/companies", APIV2.CompanyController
    resources "/api/v2/organizations", APIV2.OrganizationController
    resources "/api/v2/activity", APIV2.ActivityController
    resources "/api/v2/timeline_events", APIV2.TimelineEventController
    resources "/api/v2/card", APIV2.CardController do
      resources "/attachments", APIV2.CardAttachmentController,
        only: [:index, :create, :delete]
    end
    resources "/api/v2/tag", APIV2.TagController
    resources "/api/v2/board", APIV2.BoardController do
      put "/archive", APIV2.BoardController, :archive, as: :archive
      put "/unarchive", APIV2.BoardController, :unarchive, as: :unarchive
    end
    resources "/api/v2/board_column", APIV2.BoardColumnController

    resources "/api/v2/webhooks", APIV2.WebhookSubscriptionController
    #post "/api/v2/webhook", APIV2.WebhookController, :create
    post "/api/v2/bulk_contact_create", APIV2.BulkController, :bulk_contact_create
    post "/api/v2/bulk_tag_or_untag_contacts", APIV2.BulkController, :bulk_tag_or_untag_contacts

    get "/api/v2/user", APIV2.UserController, :index
  end

  scope "/admin" , CercleApi.Admin, as: :admin do
    pipe_through :browser # Use the default browser stack
    pipe_through :basic_auth

    resources "/users", UserController
    resources "/companies", CompanyController
    resources "/oauth_application", OauthApplicationController, except: [:show]
    #resources "/company_services", CompanyServiceController
  end

  scope "/oauth", as: "oauth" do
    post "/token", CercleApi.Oauth.TokenController, :create
    post "/revoke", CercleApi.Oauth.TokenController, :revoke
    post "/refresh", CercleApi.Oauth.TokenController, :create
  end

  scope "/oauth", as: "oauth" do
    pipe_through [:browser, :browser_auth, :require_login]
    scope "/authorize" do
      get "/", CercleApi.Oauth.AuthorizationController, :new
      post "/", CercleApi.Oauth.AuthorizationController, :create
      get "/:code", CercleApi.Oauth.AuthorizationController, :show
      delete "/", CercleApi.Oauth.AuthorizationController, :delete
    end
  end

end
