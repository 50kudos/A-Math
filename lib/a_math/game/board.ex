defmodule AMath.Game.Board do
  @piece_multiplier %{
    {0,3}  => 2, {0,11}  => 2,
    {1,5}  => 3, {1,9}   => 3,
    {2,6}  => 2, {2,8}   => 2,
    {3,0}  => 2, {3,7}   => 2, {3,14} => 2,
    {4,4}  => 3, {4,10}  => 3,
    {5,1}  => 3, {5,5}   => 3, {5,9}  => 3, {5,13} => 3,
    {6,2}  => 2, {6,6}   => 2, {6,8}  => 2, {6,12} => 2,
    {7,3}  => 2, {7,11}  => 2,
    {8,2}  => 2, {8,6}   => 2, {8,8}  => 2, {8,12} => 2,
    {9,1}  => 3, {9,5}   => 3, {9,9}  => 3, {9,13} => 3,
    {10,4} => 3, {10,10} => 3,
    {11,0} => 2, {11,7}  => 2, {11,14} => 2,
    {12,6} => 2, {12,8}  => 2,
    {13,5} => 3, {13,9}  => 3,
    {14,3} => 2, {14,11} => 2
  }
  
  @equation_multiplier %{
    {0,0}  => 3, {0,7}   => 3, {0,14} => 3,
    {1,1}  => 2, {1,13}  => 2,
    {2,2}  => 2, {2,12}  => 2,
    {3,3}  => 2, {3,11}  => 2,
    {7,0}  => 3, {7,14}  => 3,
    {11,3} => 2, {11,11} => 2,
    {12,2} => 2, {12,12} => 2,
    {13,1} => 2, {13,13} => 2,
    {14,0} => 3, {14,7}  => 3, {14,14} => 3
  }
  
  def piece_point(%{i: i, j: j, point: point}) do
    point * Map.get(@piece_multiplier, {i,j}, 1)
  end
  
  def equation_mult(%{i: i, j: j}) do
    Map.get(@equation_multiplier, {i,j}, 1)
  end

end
