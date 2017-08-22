defmodule CercleApi.APIV2.CardController do
  require Logger
  use CercleApi.Web, :controller

  alias CercleApi.{Card, Contact, Company, Organization, User, Board, CardService}

  plug CercleApi.Plug.EnsureAuthenticated
  plug CercleApi.Plug.CurrentUser

  plug :scrub_params, "card" when action in [:create, :update]

  plug :authorize_resource, model: Card, only: [:update, :delete, :show],
  unauthorized_handler: {CercleApi.Helpers, :handle_json_unauthorized},
  not_found_handler: {CercleApi.Helpers, :handle_json_not_found}

  def index(conn, %{"contact_id" => contact_id, "archived" => archived}) do
    current_user = CercleApi.Plug.current_user(conn)
    contact = Repo.get_by!(Contact, id: contact_id, company_id: current_user.company_id)

    if archived == "true" do
      cards = Contact.all_cards(contact)
    else
      cards = Contact.involved_in_cards(contact)
    end

    render(conn, "index.json", cards: cards)
  end

  def show(conn, %{"id" => id}) do
    card = Card
    |> Card.preload_data
    |> Repo.get(id)

    card_contacts = Card.contacts(card)

    board = Board
    |> Repo.get!(card.board_id)
    |> Repo.preload([:board_columns])

    render(conn, "full_card.json",
      card: card,
      card_contacts: card_contacts,
      board: board,
      attachments: card.attachments
    )
  end

  def create(conn, %{"card" => card_params}) do
    Logger.warn "In create card: #{inspect card_params}"
    current_user = CercleApi.Plug.current_user(conn)
    company = Repo.get!(Company, current_user.company_id)
    board = Repo.get!(CercleApi.Board, card_params["board_id"])

    changeset = company
    |> build_assoc(:cards)
    |> Card.changeset(card_params)

    case Repo.insert(changeset) do
      {:ok, card} ->
        card = Repo.preload(card, [:board_column, board: [:board_columns]])
        CardService.insert(current_user, card)
        conn
        |> put_status(:created)
        |> render("show.json", card: card)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def move_card_to_board_column(conn, %{"card_id" => card_id, "board_column_name" => board_column_name}) do
    Logger.warn "In move_card_to_board_column: card id: #{inspect card_id} , board column name : #{inspect board_column_name}"
    current_user = CercleApi.Plug.current_user(conn)
    origin_card = Repo.get!(Card, card_id)
    board_column = Repo.get_by(CercleApi.BoardColumn, name: board_column_name)
    changeset = Card.changeset(origin_card, %{board_column_id: board_column.id})
    case Repo.update(changeset) do
      {:ok, card} ->
        card = Repo.preload(card, [:board_column, board: [:board_columns]])
        Logger.warn "Card: #{inspect card}"
        CardService.update(current_user, card, origin_card)
        conn
        |> render("show.json", card: card)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "card" => card_params}) do
    Logger.warn "In update card: #{inspect card_params}"
    current_user = CercleApi.Plug.current_user(conn)
    origin_card = Repo.get!(Card, id)
    changeset = Card.changeset(origin_card, card_params)
    Logger.info "Origin card: #{inspect origin_card}"
    Logger.info "Card params: #{inspect card_params}"
    Logger.info "Changeset: #{inspect changeset}"
    board_column = Repo.get!(CercleApi.BoardColumn, card_params["board_column_id"])

    case board_column.name do
      "Order shipped" ->
        Logger.info "Shipppinng beerreerererer!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        contact = Repo.get(CercleApi.Contact, origin_card.contact_ids |> List.first)
        message = beer_shipped_link(id)
        CercleApi.SmsService.send_sms(contact.phone, message)
      "Lead in" ->
        contact = Repo.get(CercleApi.Contact, origin_card.contact_ids |> List.first)
        message = beer_order_link(id)
        CercleApi.SmsService.send_sms(contact.phone, message)
        Logger.info "Startingbeer order!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      _ ->
        Logger.info "Do nothing"
    end

    case Repo.update(changeset) do
      {:ok, card} ->
        card = Repo.preload(card, [:board_column, board: [:board_columns]])
        Logger.warn "Card: #{inspect card}"
        CardService.update(current_user, card, origin_card)
        conn
        |> fetch_session()
        |> fetch_flash()
        |> put_flash(:info, "information")
        |> render("show.json", card: card)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp beer_order_link(card_id) do
    "m.me/589019314615856?ref=%7B%22start_bot%22%3A%20%22Ab%20Inbev%20order%20bot%22%2C%20%22bot_params%22%20%3A%20%7B%22card_id%22%3A%20#{card_id}%7D%7D"
  end

  defp beer_shipped_link(card_id) do
    "m.me/589019314615856?ref=%7B%22start_bot%22%3A%20%22Ab%20Inbev%20shipped%20bot%22%2C%20%22bot_params%22%20%3A%20%7B%22card_id%22%3A%20#{card_id}%7D%7D"
  end

  def delete(conn, %{"id" => id}) do
    card = Repo.get!(Card, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(card)
    CardService.delete(card)

    json conn, %{status: 200}
  end
end
