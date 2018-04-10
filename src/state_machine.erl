-module(state_machine).
-export([start/0]).

start() ->
  io:fwrite("Start state machine module\n"),
  state_init().


state_init() ->
  pid_event_handler ! {state, intializing},
  io:format("State: init~n"),

  receive
    {event, first_floor_passed} ->
      state_idle()
    after 500 ->
      state_init()
  end.


state_idle() ->
  %pid_event_manager ! {state, idle},
  io:format("State: idle~n"),

  receive
    {event, first_floor_reached} ->
      io:format("First floor reached ~n")
    %moving ->
    %  state_moving();
    %order_processing ->

%    new_order ->   ;

  after 1500 ->
    state_idle()
  end.


state_open_door() ->
  pid_event_manager ! {state, floor_reached},
  receive
    floor_reached ->


    state_idle()
  end.

%state_moving() ->
%  pid_event_manager ! {state, floor_reached},
%  receive
%    floor_reached ->
%      1;
%    order_processing ->
%      state_order_processing();
%    moving_up ->
%      state_moving()
%    after 1500 ->
%      state_idle()
%    end.








