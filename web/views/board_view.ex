defmodule CercleApi.BoardView do
  use CercleApi.Web, :view
  require Logger

  def flash_msg(%{info: msg}) do
    Logger.warn "Flash message info: #{inspect msg}"
    ~E"<div class='alert alert-info'>Lalalaal</div>"
  end
  def flash_msg(msg) do
    Logger.warn "Flash message any: #{inspect msg}"
    ~E"<div class='alert alert-info'><%= #{inspect msg} %></div>"
  end
end
