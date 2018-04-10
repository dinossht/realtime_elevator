-module(elevator).
-export([start/0]).

start() ->
  {ok, Pid_elevator_interface} = elevator_interface:start(),
  register(pid_event_handler, spawn(fun() -> event_handler:start(Pid_elevator_interface) end)),
  register(pid_state_machine, spawn(fun() -> state_machine:start() end)),

  timer:sleep(1000000).
