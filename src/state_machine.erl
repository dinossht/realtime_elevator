-module(state_machine).
-export([start/0]).

-define(DOOR_OPEN_TIMEOUT_MS, 3000).
-define(FLOOR_DETECTION_DELAY_MS, 500).


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
  set_motor_direction(down),
  pid_data_storage ! {current_direction_add, down},
  receive
    {floor_detected} ->
      state_idle()
    after 500 -> state_init()
  end.

state_idle() ->
  flush_message_buffer(),
  io:format("State: idle~n"),
  set_motor_direction(stop),
  pid_data_storage ! {get_next_move, self()},
    receive
      up -> state_moving(up);
      down -> state_moving(down);
      open_door -> state_open_door();
      stop ->
        receive
          {new_order} -> state_idle()
        end
    end.


state_open_door() ->
  flush_message_buffer(),
  io:format("Door open~n"),
  set_door_open_light(on),
  timer:sleep(?DOOR_OPEN_TIMEOUT_MS),
  io:format("Door closed~n"),
  set_door_open_light(off),
  pid_data_storage ! {order_remove},
  state_idle().


state_moving(Direction) ->
  set_motor_direction(Direction),
  pid_data_storage ! {current_direction_add, Direction},
  io:format("Moving ~p~n", [Direction]),
  timer:sleep(?FLOOR_DETECTION_DELAY_MS),
  flush_message_buffer(),
  receive
    {floor_detected} ->
      state_idle()
  end.


flush_message_buffer() ->
  receive _Any -> flush_message_buffer()
  after 0 -> ok
  end.










