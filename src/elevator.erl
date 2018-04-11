-module(elevator).
-export([start/0]).

start() ->
  {ok, Pid_elevator_interface} = elevator_interface:start(),
  register(pid_elevator_interface, Pid_elevator_interface),
  register(pid_event_handler, spawn(fun() -> event_handler:start() end)),
  register(pid_state_machine, spawn(fun() -> state_machine:start() end)).

