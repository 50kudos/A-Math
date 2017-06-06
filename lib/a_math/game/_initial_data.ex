defmodule AMath.Game.Intializer do
  def sample do
    %{
      items: %{
        boardItems: [
          %{item: "1", i: 7, j: 4, point: 1},
          %{item: "+", i: 7, j: 5, point: 2},
          %{item: "1", i: 7, j: 6, point: 1},
          %{item: "=", i: 7, j: 7, point: 1},
          %{item: "2", i: 7, j: 8, point: 1}
        ],
        myItems: [
          %{item: "10", id: 1, point: 3},
          %{item: "-", id: 2, point: 2},
          %{item: "=", id: 3, point: 1},
          %{item: "=", id: 4, point: 1},
          %{item: "1", id: 5, point: 1},
          %{item: "2", id: 6, point: 1},
          %{item: "0", id: 7, point: 1},
          %{item: "9", id: 8, point: 2}
        ],
        restItems: [
          %{item: "0", ea: 4, point: 1},
          %{item: "1", ea: 5, point: 1},
          %{item: "2", ea: 5, point: 1},
          %{item: "3", ea: 5, point: 1},
          %{item: "4", ea: 5, point: 2},
          %{item: "5", ea: 4, point: 2},
          %{item: "6", ea: 4, point: 2},
          %{item: "7", ea: 4, point: 2},
          %{item: "8", ea: 4, point: 2},
          %{item: "9", ea: 3, point: 2},
          %{item: "10", ea: 1, point: 3},
          %{item: "11", ea: 1, point: 4},
          %{item: "12", ea: 2, point: 3},
          %{item: "13", ea: 1, point: 6},
          %{item: "14", ea: 1, point: 4},
          %{item: "15", ea: 1, point: 4},
          %{item: "16", ea: 1, point: 4},
          %{item: "17", ea: 1, point: 6},
          %{item: "18", ea: 1, point: 4},
          %{item: "19", ea: 1, point: 7},
          %{item: "20", ea: 1, point: 5},
          %{item: "+", ea: 4, point: 2},
          %{item: "-", ea: 3, point: 2},
          %{item: "+/-", ea: 5, point: 1},
          %{item: "x", ea: 4, point: 2},
          %{item: "÷", ea: 4, point: 2},
          %{item: "x/÷", ea: 4, point: 1},
          %{item: "=", ea: 9, point: 1},
          %{item: "blank", ea: 4, point: 0}
        ]
      }
    }
  end
end
