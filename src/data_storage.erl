-module(data_storage).
-author("dinos").
-export([]).


start() ->
  ets:new(order_storage_id, [set, named_table]),
  ets:new(prev_button_state_storage_id, [set, named_table]),
  ets:new(current_direction_storage_id, [set, named_table]),
  ets:new(current_floor_storage_id, [set, named_table]).

order_storage_add(Floor_nr, Button_type, Status) ->
  ets:insert(order_storage_id, {{Floor_nr, Button_type}, Status}).
order_storage_getStatus(Floor_nr, Button_type) ->
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
  ets:insert(prev_button_state_storage_id, {Direction}).
current_direction_getStatus(Floor_nr, Button_type) ->
  Order = ets:lookup(prev_button_state_storage_id, Direction),
  case Order of
    [] -> 0;
    [H|_] ->
      {Status} = H,
      Status
  end.
