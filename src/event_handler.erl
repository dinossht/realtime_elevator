-module(event_handler).
-export([start/1]).

start(Pid_elevator_interface) ->
  io:fwrite("Start event handler module\n"),
  event_handle_startup(Pid_elevator_interface).


event_handle_startup(Pid_elevator_interface) ->
  %set correct floor indicator, turn off lights etc.
  receive
    {state, intializing} ->
      io:format("event_handle_startup~n"),
      elevator_interface:set_motor_direction(Pid_elevator_interface, down),
      %timer:sleep(20),
      case elevator_interface:get_floor_sensor_state(Pid_elevator_interface) of
        0 ->
          event_handle_startupFinished(Pid_elevator_interface);
        _ ->
          event_handle_startup(Pid_elevator_interface)
      end
  end.


event_handle_startupFinished(Pid_elevator_interface) ->
  elevator_interface:set_motor_direction(Pid_elevator_interface, stop),
  pid_state_machine ! {event, first_floor_passed}.






%eventGenerator_raiseButtonPressed() -
