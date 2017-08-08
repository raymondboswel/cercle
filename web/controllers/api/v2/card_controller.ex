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

  def update(conn, %{"id" => id, "card" => card_params}) do
    Logger.warn "In update card: #{inspect card_params}"
    current_user = CercleApi.Plug.current_user(conn)
    origin_card = Repo.get!(Card, id)
    changeset = Card.changeset(origin_card, card_params)
    Logger.info "Origin card: #{inspect origin_card}"
    Logger.info "Card params: #{inspect card_params}"
    Logger.info "Changeset: #{inspect changeset}"

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

  def delete(conn, %{"id" => id}) do
    card = Repo.get!(Card, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(card)
    CardService.delete(card)

    json conn, %{status: 200}
  end
end
