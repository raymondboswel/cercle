defmodule CercleApi.SmsService do
  require Logger

  def send_sms(phone_number, message) do
    auth_token = authenticate()
    rails_api_url = Application.get_env(:higuru_auth, :rails_api_url)
    body = %{phone_number: phone_number, message: message} |> Poison.encode! 
    headers = %{"Authorization" => auth_token, "Content-Type" => "application/json"}
    Logger.debug "Body: #{inspect body}"
    {_, result} = HTTPoison.post(rails_api_url <> "/system_users/send_sms", body, headers, [connect_timeout: 50000, recv_timeout: 50000, timeout: 50000])
    Logger.debug "result: #{inspect result}"
  end

  defp authenticate do
    username = Application.get_env(:higuru_auth, :username)
    password = Application.get_env(:higuru_auth, :password)
    rails_api_url = Application.get_env(:higuru_auth, :rails_api_url)
    json = %{auth_id: username, password: password} |> Poison.encode!
    Logger.debug "Rails url: #{rails_api_url}"
    {_, result} = HTTPoison.post(rails_api_url <> "/auth", json, %{"content-type" => "application/json"}, [hackney: [:insecure]])
    body = result.body |> Poison.decode!
    token = body["auth_token"]
  end
end 