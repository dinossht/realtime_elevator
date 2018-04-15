-module(event_handler).
-export([start/0]).

-define(ORDER_BUTTON_POLL_PERIOD_MS, 50).
-define(FLOOR_SENSOR_POLL_PERIOD_MS, 500).

%TODO: During startup: set correct floor indicator, turn off lights etc.
%TODO: Remember to not poll up on 4th floor up etc.
%TODO: Fix prev_button maybe?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elevator interface wrapper %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_order_button_state(Floor_nr, Button_type) ->
  elevator_interface:get_order_button_state(pid_elevator_interface, Floor_nr, Button_type).
get_floor_sensor_state() ->
  elevator_interface:get_floor_sensor_state(pid_elevator_interface).
set_floor_indicator(Floor_nr) ->
  elevator_interface:set_floor_indicator(pid_elevator_interface, Floor_nr).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

start() ->
  io:format("Start event handler module ~n"),
  spawn(fun() -> event_handle_cabButtonClick(0) end),
  spawn(fun() -> event_handle_upButtonClick(0) end),
  spawn(fun() -> event_handle_downButtonClick(1) end),
  spawn(fun() -> event_handle_floorDetected() end).


event_handle_floorDetected() ->
  Floor_nr = get_floor_sensor_state(),
  case Floor_nr of
    between_floors ->
      io:format("");
    _ ->
      pid_state_machine ! {floor_detected},
      pid_data_storage ! {current_floor_add, Floor_nr},
      set_floor_indicator(Floor_nr)
  end,
  timer:sleep(?FLOOR_SENSOR_POLL_PERIOD_MS),
  event_handle_floorDetected().


event_handle_cabButtonClick(Floor_nr) when Floor_nr > 3 ->
  event_handle_cabButtonClick(0);
event_handle_cabButtonClick(Floor_nr) when Floor_nr =< 3 ->
  Button_state = get_order_button_state(Floor_nr, cab),
  Prev_state = Button_state, % = data_storage:prev_button_state_getStatus(Floor_nr, cab),

  %case (Button_state /= Prev_state) and (Button_state == 1) of
  case (Button_state == 1) of
    true ->
      pid_data_storage ! {order_add, Floor_nr, cab, 1},
      pid_state_machine ! {new_order};
    false -> timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS)
  end,

  event_handle_cabButtonClick(Floor_nr + 1).

event_handle_upButtonClick(Floor_nr) when Floor_nr > 2 ->
  event_handle_upButtonClick(0);
event_handle_upButtonClick(Floor_nr) when Floor_nr =< 2 ->
  Button_state = get_order_button_state(Floor_nr, hall_up),
  Prev_state = Button_state, % = data_storage:prev_button_state_getStatus(Floor_nr, hall_up),

  %case (Button_state /= Prev_state) and (Button_state == 1) of
  case (Button_state == 1) of
    true ->
      %pid_data_storage ! {order_add, Floor_nr, up, 1},
      global_data:add_order(Floor_nr, up),
      pid_state_machine ! {new_order};
    false -> timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS)
  end,

  event_handle_upButtonClick(Floor_nr + 1).

event_handle_downButtonClick(Floor_nr) when Floor_nr > 3 ->
  event_handle_downButtonClick(1);
event_handle_downButtonClick(Floor_nr) when Floor_nr =< 3 ->
  Button_state = get_order_button_state(Floor_nr, hall_down),
  Prev_state = Button_state, % = data_storage:prev_button_state_getStatus(Floor_nr, hall_down),

  %case (Button_state /= Prev_state) and (Button_state == 1) of
  case (Button_state == 1) of
    true ->
      %pid_data_storage ! {order_add, Floor_nr, down, 1},
      global_data:add_order(Floor_nr, down),
      pid_state_machine ! {new_order};
    false -> timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS)
  end,

  event_handle_downButtonClick(Floor_nr + 1).













