defmodule RealtimeChatWeb.RoomLive.Index do
  use RealtimeChatWeb, :live_view

  alias RealtimeChat.Chat
  alias RealtimeChat.Chat.Room

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(RealtimeChat.PubSub, "rooms_updated")
    end
    {:ok, stream(socket, :rooms, Chat.list_rooms())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Chat.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Chat Rooms")
    |> assign(:room, nil)
  end

  @impl true
  def handle_info({RealtimeChatWeb.RoomLive.FormComponent, {:saved, room}}, socket) do
    Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "rooms_updated",
      {:updated, room})
    {:noreply, stream_insert(socket, :rooms, room)}
  end

  def handle_info({:updated, room}, socket) do
    {:noreply, stream_insert(socket, :rooms, room)}
  end

  def handle_info({:deleted, room}, socket) do
    {:noreply, stream_delete(socket, :rooms, room)}
  end

  @impl true
  @spec handle_event(<<_::48>>, map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("delete", %{"id" => id}, socket) do
    room = Chat.get_room!(id)
    {:ok, _} = Chat.delete_room(room)

    Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "rooms_updated",
      {:deleted, room})
    {:noreply, stream_delete(socket, :rooms, room)}
  end
end
