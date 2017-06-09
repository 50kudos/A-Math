defmodule AMath.Game.Intializer do
  def sample do
    %{
      items: %{
        boardItems: [],
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
  
  def raw do
    [
      List.duplicate("0",5),
      List.duplicate("1",6),
      List.duplicate("2",6),
      List.duplicate("3",5),
      List.duplicate("4",5),
      List.duplicate("5",4),
      List.duplicate("6",4),
      List.duplicate("7",4),
      List.duplicate("8",4),
      List.duplicate("9",4),
      List.duplicate("10",2),
      List.duplicate("11",1),
      List.duplicate("12",2),
      List.duplicate("13",1),
      List.duplicate("14",1),
      List.duplicate("15",1),
      List.duplicate("16",1),
      List.duplicate("17",1),
      List.duplicate("18",1),
      List.duplicate("19",1),
      List.duplicate("20",1),
      List.duplicate("+",4),
      List.duplicate("-",4),
      List.duplicate("+/-",5),
      List.duplicate("x",4),
      List.duplicate("x/÷",4),
      List.duplicate("=",11),
      List.duplicate("blank",4),
    ]
    |> List.flatten()
  end

end
