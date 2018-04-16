%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Credits:
% This code is inspired by
% Kjetil Kjeka's Real-time-elevator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-module(state_machine).
-export([start/0]).

-define(DOOR_OPEN_TIMEOUT_MS, 3000).
-define(FLOOR_DETECTION_DELAY_MS, 500).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elevator interface wrapper %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_motor_direction(Direction) ->
  elevator_interface:set_motor_direction(pid_elevator_interface, Direction).
set_door_open_light(State) ->
  elevator_interface:set_door_open_light(pid_elevator_interface, State).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

start() ->
  io:format("Start state machine module~n"),
  state_init().

state_init() ->
  set_motor_direction(down),
  % Initialize current direction as direction down
  pid_order_processor ! {current_direction_add, down},
  receive
    {floor_detected} ->
      state_idle()
    after 500 -> state_init()
  end.

state_idle() ->
  flush_message_buffer(),
  set_motor_direction(stop),
  pid_order_processor ! {get_next_move, self()},
    receive
      up ->
        io:format("Moving ~p~n", [up]),
        state_moving(up);
      down ->
        io:format("Moving ~p~n", [down]),
        state_moving(down);
      open_door -> state_open_door();
      stop ->
        receive
          {new_order} ->
            io:format("State: idle~n"),
            state_idle()
        end
    end.

state_open_door() ->
  flush_message_buffer(),
  io:format("Door open~n"),
  set_door_open_light(on),
  timer:sleep(?DOOR_OPEN_TIMEOUT_MS),
  io:format("Door closed~n"),
  set_door_open_light(off),
  pid_order_processor ! {order_remove},
  state_idle().

state_moving(Direction) ->
  set_motor_direction(Direction),
  pid_order_processor ! {current_direction_add, Direction},
  timer:sleep(?FLOOR_DETECTION_DELAY_MS),
  flush_message_buffer(),
  receive
    {floor_detected} ->
      state_idle()
  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clear up buffer which tempts to fill up during message passing
% This is used to get the latest message from other processes
flush_message_buffer() ->
  receive _Any -> flush_message_buffer()
  after 0 -> ok
  end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%










