-module(event_handler).
-export([start/0]).

-define(ORDER_BUTTON_POLL_PERIOD_MS, 50).
-define(FLOOR_SENSOR_POLL_PERIOD_MS, 500).

-define(NUM_OF_FLOORS, 4).

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
    between_floors -> io:format("");
    _ ->
      pid_state_machine ! {floor_detected},
      pid_order_processor ! {current_floor_add, Floor_nr},
      set_floor_indicator(Floor_nr)
  end,
  timer:sleep(?FLOOR_SENSOR_POLL_PERIOD_MS),
  event_handle_floorDetected().

event_handle_cabButtonClick(Floor_nr) when Floor_nr > (?NUM_OF_FLOORS - 1) ->
  event_handle_cabButtonClick(0);
event_handle_cabButtonClick(Floor_nr) when Floor_nr =< (?NUM_OF_FLOORS - 1) ->
  Button_state = get_order_button_state(Floor_nr, cab),
  case (Button_state == 1) of
    true ->
      pid_order_processor ! {order_add, Floor_nr, cab, 1},
      pid_state_machine ! {new_order};
    false -> timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS)
  end,
  event_handle_cabButtonClick(Floor_nr + 1).

event_handle_upButtonClick(Floor_nr) when Floor_nr > (?NUM_OF_FLOORS - 2) ->
  event_handle_upButtonClick(0);
event_handle_upButtonClick(Floor_nr) when Floor_nr =< (?NUM_OF_FLOORS - 2) ->
  Button_state = get_order_button_state(Floor_nr, hall_up),
  case (Button_state == 1) of
    true ->
      global_data:add_order(Floor_nr, up, node()),
      pid_state_machine ! {new_order};
    false -> timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS)
  end,
  event_handle_upButtonClick(Floor_nr + 1).

event_handle_downButtonClick(Floor_nr) when Floor_nr > (?NUM_OF_FLOORS - 1) ->
  event_handle_downButtonClick(1);
event_handle_downButtonClick(Floor_nr) when Floor_nr =< (?NUM_OF_FLOORS - 1) ->
  Button_state = get_order_button_state(Floor_nr, hall_down),
  case (Button_state == 1) of
    true ->
      global_data:add_order(Floor_nr, down, node()),
      pid_state_machine ! {new_order};
    false -> timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS)
  end,
  event_handle_downButtonClick(Floor_nr + 1).













