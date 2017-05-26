defmodule AMath.Web.ItemControllerTest do
  use AMath.Web.ConnCase

  alias AMath.Game
  alias AMath.Game.Item

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:item) do
    {:ok, item} = Game.create_item(@create_attrs)
    item
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, item_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "creates item and renders item when data is valid", %{conn: conn} do
    conn = post conn, item_path(conn, :create), item: @create_attrs
    assert %{"id" => id} = json_response(conn, 201)["data"]

    conn = get conn, item_path(conn, :show, id)
    assert json_response(conn, 200)["data"] == %{
      "id" => id}
  end

  test "does not create item and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, item_path(conn, :create), item: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates chosen item and renders item when data is valid", %{conn: conn} do
    %Item{id: id} = item = fixture(:item)
    conn = put conn, item_path(conn, :update, item), item: @update_attrs
    assert %{"id" => ^id} = json_response(conn, 200)["data"]

    conn = get conn, item_path(conn, :show, id)
    assert json_response(conn, 200)["data"] == %{
      "id" => id}
  end

  test "does not update chosen item and renders errors when data is invalid", %{conn: conn} do
    item = fixture(:item)
    conn = put conn, item_path(conn, :update, item), item: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen item", %{conn: conn} do
    item = fixture(:item)
    conn = delete conn, item_path(conn, :delete, item)
    assert response(conn, 204)
    assert_error_sent 404, fn ->
      get conn, item_path(conn, :show, item)
    end
  end
end
