-module(state_machine).
-export([start/0]).

-define(DOOR_OPEN_TIMEOUT_MS, 3000).


%TODO Should update state data to send via network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elevator interface wrapper %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_motor_direction(Direction) ->
  elevator_interface:set_motor_direction(pid_elevator_interface, Direction).
set_door_open_light(State) ->
  elevator_interface:set_door_open_light(pid_elevator_interface, State).
set_floor_indicator(Floor_nr) ->
  elevator_interface:set_floor_indicator(pid_elevator_interface, Floor_nr).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

start() ->
  io:format("Start state machine module~n"),
  state_init().


state_init() ->
  io:format("State: startup~n"),
  elevator_interface:set_motor_direction(pid_elevator_interface, down),
  receive
    {floor_detected} -> state_idle()
    after 500 -> state_init()
  end.


state_idle() ->
  io:format("State: idle~n"),
  set_motor_direction(stop),
  Next_move = stop,%request_next_move(),
    case Next_move of
      up -> state_moving(up);
      down -> state_moving(down);
      open_door -> state_open_door();
      stop ->
        receive
          {new_order} -> state_idle()
        end
    end.



state_open_door() ->
  io:format("Door open~n"),
  set_door_open_light(on),
  timer:sleep(?DOOR_OPEN_TIMEOUT_MS),
  io:format("Door closed~n"),
  set_door_open_light(off),
  state_idle().


state_moving(Direction) ->
  set_motor_direction(Direction),
  receive
    {floor_detected} ->
      state_idle()
  end.










