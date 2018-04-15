-module(data_storage).
-export([start/0, order_add/3, order_getStatus/2, prev_button_state_add/3, prev_button_state_getStatus/2, current_direction_add/1, current_direction_getStatus/0, current_floor_add/1, current_floor_getStatus/0]).
-export([get_next_move/0]).

%TODO: Fix bestilling i current_floor når bestilling er motsatt retning.

set_order_button_light_(cab, Floor_nr, State) ->
  elevator_interface:set_order_button_light(pid_elevator_interface, cab, Floor_nr, State);
set_order_button_light_(up, Floor_nr, State) ->
  elevator_interface:set_order_button_light(pid_elevator_interface, hall_up, Floor_nr, State);
set_order_button_light_(down, Floor_nr, State) ->
  elevator_interface:set_order_button_light(pid_elevator_interface, hall_down, Floor_nr, State).


start() ->
  io:format("Start data storage module ~n"),
  ets:new(order_storage_id, [set, named_table]),
  ets:new(current_direction_storage_id, [set, named_table]),
  ets:new(current_floor_storage_id, [set, named_table]),
  %ets:new(prev_button_state_storage_id, [set, named_table]),
  data_storage().

print(L) ->
  case L of
    [] -> io:format("Order empty~n");
    _ -> io:format("Order : ~62p~n", L)
  end.


data_storage() ->
  receive
    {current_floor_add, Floor_nr} -> current_floor_add(Floor_nr);
    {order_add, Floor_nr, Button_type, Status} -> order_add(Floor_nr, Button_type, Status);
    {current_direction_add, Direction} -> current_direction_add(Direction);
    {order_remove} ->
      %order_add(current_floor_getStatus(), current_direction_getStatus(), 0),
      order_add(current_floor_getStatus(), cab, 0),
      order_add(current_floor_getStatus(), up, 0),
      order_add(current_floor_getStatus(), down, 0);
    {get_direction, PID} -> PID ! current_direction_getStatus();
    {get_floor, PID} -> PID ! current_floor_getStatus();
    {get_next_move, PID} -> PID ! get_next_move();
    {get_status, PID} -> 
      io:format("Floor~p  Dir ~p~n", [current_floor_getStatus(), current_direction_getStatus()]),
      PID ! {current_floor_getStatus(), current_direction_getStatus()}
  end,
  data_storage().





order_add(Floor_nr, Button_type, Status) ->
  case Status == 1 of
    true ->
      set_order_button_light_(Button_type, Floor_nr, on);
    false ->
      global_data:remove_order(Floor_nr, Button_type),
      set_order_button_light_(Button_type, Floor_nr, off)
  end,
  ets:insert(order_storage_id, {{Floor_nr, Button_type}, Status}),
  Order = ets:lookup(order_storage_id, {Floor_nr, Button_type}),
  print(Order).

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


request_at_floor(Floor_nr, Direction) ->
  (order_getStatus(Floor_nr, Direction) == 1) or (order_getStatus(Floor_nr, cab) == 1).
request_at_floor(Floor_nr) ->
  request_at_floor(Floor_nr, up) or request_at_floor(Floor_nr, down).
request_above(Floor_nr) ->
  case Floor_nr < 4 - 1 of
    true ->
      case request_at_floor(Floor_nr + 1) of
        true -> true;
        false -> request_above(Floor_nr + 1)
      end;
    false -> false
  end.
request_below(Floor_nr) ->
  case Floor_nr > 0 of
    true ->
      case request_at_floor(Floor_nr - 1) of
        true -> true;
        false -> request_below(Floor_nr - 1)
      end;
    false -> false
  end.


get_next_move() ->
  Current_direction = current_direction_getStatus(),
  Current_floor_nr = current_floor_getStatus(),
  case request_at_floor(Current_floor_nr) of
    true -> open_door;
    false ->
      case Current_direction of
        up ->
          case request_above(Current_floor_nr) of
            true -> up;
            false ->
              case request_below(Current_floor_nr) of
                true -> down;
                false ->
                  io:format("dir up stop ~n"),
                  stop
              end
          end;
        down ->
          case request_below(Current_floor_nr) of
            true -> down;
            false ->
              case request_above(Current_floor_nr) of
                true -> up;
                false ->
                  io:format("dir down stop ~n"),
                  stop
              end
          end;
        _ ->
          io:format("default ~n"),
          stop
      end
  end.
  



num_of_active_orders( Search_node, [], Number ) ->
    Number;
num_of_active_orders( Search_node, [ Item | ListTail ], Number ) ->
  
  %io:fwrite("Element: ~p.  Elev: ~p.  ListTail: ~p.",[Element,Elev,ListTail]),
  {order, Floor, Button_type, Node} = Item,
    case ( Node == Search_node ) of
        true    ->  
          num_of_active_orders(Search_node, ListTail, Number+1);
        false   ->  num_of_active_orders(Search_node, ListTail, Number)
    end.





