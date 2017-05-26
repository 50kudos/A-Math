defmodule AMath.GameTest do
  use AMath.DataCase

  alias AMath.Game
  alias AMath.Game.Item

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:item, attrs \\ @create_attrs) do
    {:ok, item} = Game.create_item(attrs)
    item
  end

  test "list_items/1 returns all items" do
    item = fixture(:item)
    assert Game.list_items() == [item]
  end

  test "get_item! returns the item with given id" do
    item = fixture(:item)
    assert Game.get_item!(item.id) == item
  end

  test "create_item/1 with valid data creates a item" do
    assert {:ok, %Item{} = item} = Game.create_item(@create_attrs)
  end

  test "create_item/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Game.create_item(@invalid_attrs)
  end

  test "update_item/2 with valid data updates the item" do
    item = fixture(:item)
    assert {:ok, item} = Game.update_item(item, @update_attrs)
    assert %Item{} = item
  end

  test "update_item/2 with invalid data returns error changeset" do
    item = fixture(:item)
    assert {:error, %Ecto.Changeset{}} = Game.update_item(item, @invalid_attrs)
    assert item == Game.get_item!(item.id)
  end

  test "delete_item/1 deletes the item" do
    item = fixture(:item)
    assert {:ok, %Item{}} = Game.delete_item(item)
    assert_raise Ecto.NoResultsError, fn -> Game.get_item!(item.id) end
  end

  test "change_item/1 returns a item changeset" do
    item = fixture(:item)
    assert %Ecto.Changeset{} = Game.change_item(item)
  end
end
