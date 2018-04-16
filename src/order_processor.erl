-module(order_processor).
-export([start/0, order_add/3, order_getStatus/2, current_direction_add/1, current_direction_getStatus/0, current_floor_add/1, current_floor_getStatus/0]).
-export([get_next_move/0]).

-define(NUMB_OF_ORDERS, 4).

set_order_button_light_(cab, Floor_nr, State) ->
  elevator_interface:set_order_button_light(pid_elevator_interface, cab, Floor_nr, State);
set_order_button_light_(up, Floor_nr, State) ->
  elevator_interface:set_order_button_light(pid_elevator_interface, hall_up, Floor_nr, State);
set_order_button_light_(down, Floor_nr, State) ->
  elevator_interface:set_order_button_light(pid_elevator_interface, hall_down, Floor_nr, State).

start() ->
  io:format("Start order processor module ~n"),
  ets:new(order_storage_id, [set, named_table]),
  ets:new(current_direction_storage_id, [set, named_table]),
  ets:new(current_floor_storage_id, [set, named_table]),
  local_data_storage().

local_data_storage() ->
  receive
    {current_floor_add, Floor_nr} ->
      current_floor_add(Floor_nr);
    {order_add, Floor_nr, Button_type, Status} ->
      order_add(Floor_nr, Button_type, Status);
    {current_direction_add, Direction} ->
      current_direction_add(Direction);
    {order_remove} ->
      remove_order_at_current_floor();
    {get_direction, PID} ->
      PID ! current_direction_getStatus();
    {get_floor, PID} ->
      PID ! current_floor_getStatus();
    {get_next_move, PID} ->
      PID ! get_next_move();
    {get_status, PID} ->
      PID ! {num_of_active_orders(), current_floor_getStatus(), current_direction_getStatus()}
  end,
  local_data_storage().

% Status 1 = Add order, Status 0 = remove order
order_add(Floor_nr, Button_type, Status) ->
  case Status == 1 of
    true -> set_order_button_light_(Button_type, Floor_nr, on);
    false ->
      global_data:remove_order(Floor_nr, Button_type),
      set_order_button_light_(Button_type, Floor_nr, off)
  end,
  % Store order
  ets:insert(order_storage_id, {{Floor_nr, Button_type}, Status}).

order_getStatus(Floor_nr, Button_type) ->
  Order = ets:lookup(order_storage_id, {Floor_nr, Button_type}),
  case Order of
    [] -> 0;
    [H|_] ->
      {{_,_},Status} = H,
      Status
  end.

current_direction_add(Direction) ->
  ets:insert(current_direction_storage_id, {direction, Direction}).
current_direction_getStatus() ->
  Order = ets:lookup(current_direction_storage_id, direction),
  case Order of
    [] -> 0;
    [H|_] ->
      {direction, Direction} = H,
      Direction
  end.

current_floor_add(Floor_nr) ->
  ets:insert(current_floor_storage_id, {floor_nr, Floor_nr}).
current_floor_getStatus() ->
  Order = ets:lookup(current_floor_storage_id, floor_nr),
  case Order of
    [] -> 0;
    [H|_] ->
      {floor_nr, Floor_nr} = H,
      Floor_nr
  end.

order_at_floor(Floor_nr, Direction) ->
  (order_getStatus(Floor_nr, Direction) == 1) or (order_getStatus(Floor_nr, cab) == 1).
order_at_floor(Floor_nr) ->
  order_at_floor(Floor_nr, up) or order_at_floor(Floor_nr, down).
order_above(Floor_nr) ->
  case Floor_nr < (?NUMB_OF_ORDERS - 1) of
    true ->
      case order_at_floor(Floor_nr + 1) of
        true -> true;
        false -> order_above(Floor_nr + 1)
      end;
    false -> false
  end.
order_below(Floor_nr) ->
  case Floor_nr > 0 of
    true ->
      case order_at_floor(Floor_nr - 1) of
        true -> true;
        false -> order_below(Floor_nr - 1)
      end;
    false -> false
  end.

get_next_move() ->
  Current_direction = current_direction_getStatus(),
  Current_floor_nr = current_floor_getStatus(),
  case order_at_floor(Current_floor_nr) of
    true -> open_door;
    false ->
      case Current_direction of
        up ->
          case order_above(Current_floor_nr) of
            true -> up;
            false ->
              case order_below(Current_floor_nr) of
                true -> down;
                false ->
                  %io:format("dir up stop ~n"),
                  stop
              end
          end;
        down ->
          case order_below(Current_floor_nr) of
            true -> down;
            false ->
              case order_above(Current_floor_nr) of
                true -> up;
                false ->
                  %io:format("dir down stop ~n"),
                  stop
              end
          end;
        _ -> stop
      end
  end.

remove_order_at_current_floor() ->
  order_add(current_floor_getStatus(), cab, 0),
  order_add(current_floor_getStatus(), up, 0),
  order_add(current_floor_getStatus(), down, 0).

num_of_active_orders() ->
  order_getStatus(0, up) +
  order_getStatus(0, cab) +
  order_getStatus(1, up) +
  order_getStatus(1, down) +
  order_getStatus(1, cab) +
  order_getStatus(2, up) +
  order_getStatus(2, down) +
  order_getStatus(2, cab) +
  order_getStatus(3, down) +
  order_getStatus(3, cab).




