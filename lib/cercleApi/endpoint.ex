defmodule CercleApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :cercleApi

  socket "/socket", CercleApi.UserSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :cercleApi, gzip: false,
    only: ~w(adminlte css fonts images js favicon.ico robots.txt 1AC8F311D323E9FA653A47C452CAB466.txt genii.html)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_cercleApi_key",
    signing_salt: "AnZWLL+M"

  plug CercleApi.Router
end
