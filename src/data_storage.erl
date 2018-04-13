-module(data_storage).
-export([start/0, order_add/3, order_getStatus/2, prev_button_state_add/3, prev_button_state_getStatus/2, current_direction_add/1, current_direction_getStatus/0, current_floor_add/1, current_floor_getStatus/0]).


start() ->
  io:format("Start data storage module ~n"),
  ets:new(order_storage_id, [set, named_table]),
  ets:new(prev_button_state_storage_id, [set, named_table]),
  ets:new(current_direction_storage_id, [set, named_table]),
  ets:new(current_floor_storage_id, [set, named_table]).


order_add(Floor_nr, Button_type, Status) ->
  ets:insert(order_storage_id, {{Floor_nr, Button_type}, Status}).
order_getStatus(Floor_nr, Button_type) ->
  Order = ets:lookup(order_storage_id, {Floor_nr, Button_type}),
  case Order of
    [] -> 0;
    [H|_] ->
      {{_,_},Status} = H,
      Status
  end.


prev_button_state_add(Floor_nr, Button_type, Status) ->
  ets:insert(prev_button_state_storage_id, {{Floor_nr, Button_type},Status}).
prev_button_state_getStatus(Floor_nr, Button_type) ->
  Order = ets:lookup(prev_button_state_storage_id, {Floor_nr, Button_type}),
  case Order of
    [] -> 0;
    [H|_] ->
      {{_,_},Status} = H,
      Status
  end.


current_direction_add(Direction) ->
  ets:insert(prev_button_state_storage_id, {direction, Direction}).
current_direction_getStatus() ->
  Order = ets:lookup(prev_button_state_storage_id, direction),
  case Order of
    [] -> 0;
    [H|_] ->
      {direction, Direction} = H,
      Direction
  end.


current_floor_add(Floor_nr) ->
  ets:insert(prev_button_state_storage_id, {floor_nr, Floor_nr}).
current_floor_getStatus() ->
  Order = ets:lookup(prev_button_state_storage_id, floor_nr),
  case Order of
    [] -> 0;
    [H|_] ->
      {floor_nr, Floor_nr} = H,
      Floor_nr
  end.
