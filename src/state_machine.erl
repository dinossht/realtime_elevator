-module(state_machine).
-export([start/0]).

-define(DOOR_OPEN_TIMEOUT_MS, 3000).


%TODO Should update data to send via network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elevator interface wrapper %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_motor_direction(Direction) ->
  elevator_interface:set_motor_direction(pid_elevator_interface, Direction).
set_door_open_light(State) ->
  elevator_interface:set_door_open_light(pid_elevator_interface, State).
set_floor_indicator(Floor_nr) ->
  elevator_interface:set_floor_indicator(pid_elevator_interface, Floor_nr).


start() ->
  io:format("Start state machine module~n"),
  state_init().


state_init() ->
  io:format("State: init ~n"),
  pid_event_handler ! {state, intializing},

  receive
    {event, first_floor_passed} ->
      state_idle()
    after 500 ->
      state_init()
  end.


state_idle() ->
  io:format("State: idle~n"),
  receive
    {event, new_order, Direction} ->
      io:format("neworder~n"),
      set_motor_direction(Direction),
      state_moving(Direction);
    {event, order_floor_reached} ->
      set_motor_direction(stop),
      state_open_door()
  after 1500 ->
    state_idle()
  end.


state_open_door() ->
  io:format("Door open~n"),
  set_door_open_light(on),
  timer:sleep(?DOOR_OPEN_TIMEOUT_MS),
  io:format("Door closed~n"),
  set_door_open_light(off),
  state_idle().


state_moving(Direction) ->
  io:format("State: Moving up ~n"),
  receive
    {event, floor_detected, Floor_nr} ->
      set_floor_indicator(Floor_nr),
      set_motor_direction(stop),
      state_idle()
  after 1500 ->
    state_moving(Direction)
  end.









