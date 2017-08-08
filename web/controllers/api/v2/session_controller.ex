defmodule CercleApi.APIV2.SessionController do
  use CercleApi.Web, :controller
  alias CercleApi.User

  def create(conn, %{"login" => login, "password" => password}) do
    case CercleApi.Session.authenticate(login, password) do
      {:ok, user} ->
        new_conn = Guardian.Plug.api_sign_in(conn, user)
        jwt = Guardian.Plug.current_token(new_conn)
        {:ok, claims} = Guardian.Plug.claims(new_conn)
        exp = Map.get(claims, "exp")

        new_conn
        |> put_resp_header("authorization", "Bearer #{jwt}")
        |> put_resp_header("x-expires", Integer.to_string(exp))
        |> json(%{user: user, jwt: jwt, exp: exp})
      :error ->
        conn
          |> send_resp(401, "Could not authenticate with email/password")
    end
  end

end