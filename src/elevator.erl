-module(elevator).
-export([start/0]).

start() ->
  network_manager:start(),
  {ok, Pid_elevator_interface} = elevator_interface:start(),
  register(pid_elevator_interface, Pid_elevator_interface),
  register(pid_data_storage, spawn(fun() -> data_storage:start() end)),
  register(pid_state_machine, spawn(fun() -> state_machine:start() end)),
  register(pid_event_handler, spawn(fun() -> event_handler:start() end)),
  global_data:start().


