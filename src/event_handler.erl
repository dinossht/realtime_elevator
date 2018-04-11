-module(event_handler).
-export([start/0]).

-define(ORDER_BUTTON_POLL_PERIOD_MS, 500).
-define(FLOOR_SENSOR_POLL_PERIOD_MS, 500).

%TODO: During startup: set correct floor indicator, turn off lights etc.
%TODO: Remember to not poll up on 4th floor up etc.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elevator interface wrapper %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


get_order_button_state(Floor_nr, Button_type) ->
  elevator_interface:get_order_button_state(pid_elevator_interface, Floor_nr, Button_type).
get_floor_sensor_state() ->
  elevator_interface:get_floor_sensor_state(pid_elevator_interface).

set_order_button_light(Button_type, Floor_nr, State) ->
  elevator_interface:set_order_button_light(pid_elevator_interface, Button_type, Floor_nr, State).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


start() ->
  io:format("Start event handler module ~n"),
  spawn(fun() -> event_handle_cabButtonClick(0) end),
  spawn(fun() -> event_handle_upButtonClick(0) end),
  spawn(fun() -> event_handle_downButtonClick(1) end),
  spawn(fun() -> event_handle_floorDetected() end),

  spawn(fun() -> event_handle_newOrder() end),
  spawn(fun() -> event_handle_orderFloorReached() end),

  event_handle_startup().


event_handle_startup() ->
  receive
    {state, intializing} ->
      io:format("Event handle startup ~n"),
      elevator_interface:set_motor_direction(pid_elevator_interface, down),
      case elevator_interface:get_floor_sensor_state(pid_elevator_interface) of
        0 ->
          event_handle_startupFinished();
        _ ->
          event_handle_startup()
      end
  end.


event_handle_startupFinished() ->
  io:format("Event handle startup finished ~n"),
  elevator_interface:set_motor_direction(pid_elevator_interface, stop),
  pid_state_machine ! {event, first_floor_passed}.

event_handle_cabButtonClick(Floor_nr) when Floor_nr > 3 ->
  event_handle_cabButtonClick(0);
event_handle_cabButtonClick(Floor_nr) when Floor_nr =< 3 ->
  Button_state = get_order_button_state(Floor_nr, cab),

  case Button_state of
    0 -> io:format("");
    1 -> io:format("Cab pressed ~n")
  end,

  timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS),
  event_handle_cabButtonClick(Floor_nr + 1).

event_handle_upButtonClick(Floor_nr) when Floor_nr > 2 ->
  event_handle_upButtonClick(0);
event_handle_upButtonClick(Floor_nr) when Floor_nr =< 2 ->
  Button_state = get_order_button_state(Floor_nr, hall_up),

  case Button_state of
    0 -> io:format("");
    1 -> io:format("Up pressed ~n")
  end,

  timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS),
  event_handle_upButtonClick(Floor_nr + 1).

event_handle_downButtonClick(Floor_nr) when Floor_nr > 3 ->
  event_handle_downButtonClick(1);
event_handle_downButtonClick(Floor_nr) when Floor_nr =< 3 ->
  Button_state = get_order_button_state(Floor_nr, hall_down),

  case Button_state of
    0 -> io:format("");
    1 -> io:format("Down pressed ~n")
  end,

  timer:sleep(?ORDER_BUTTON_POLL_PERIOD_MS),
  event_handle_downButtonClick(Floor_nr + 1).


event_handle_floorDetected() ->
  Sensor_state = get_floor_sensor_state(),
  case Sensor_state of
    between_floors -> io:format("Between~n");
    _ -> pid_state_machine ! {event, floor_detected, Sensor_state}
  end,
  timer:sleep(?FLOOR_SENSOR_POLL_PERIOD_MS),
  event_handle_floorDetected().


event_handle_newOrder() ->
  %pid_state_machine ! {event, new_order, up},
  event_handle_newOrder().


event_handle_orderFloorReached() ->
  pid_state_machine ! {event, order_floor_reached},
  event_handle_orderFloorReached().












