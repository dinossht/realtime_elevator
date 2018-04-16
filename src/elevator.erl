-module(elevator).
-export([start1/0, start2/0, start/0]).


start1() ->

  network_manager:start1(),
  {ok, Pid_elevator_interface} = elevator_interface:start1(),
  register(pid_elevator_interface, Pid_elevator_interface),
  register(pid_data_storage, spawn(fun() -> data_storage:start() end)),
  register(pid_state_machine, spawn(fun() -> state_machine:start() end)),
  register(pid_event_handler, spawn(fun() -> event_handler:start() end)).


start2() ->

  network_manager:start2(),
  {ok, Pid_elevator_interface} = elevator_interface:start2(),
  register(pid_elevator_interface, Pid_elevator_interface),
  register(pid_data_storage, spawn(fun() -> data_storage:start() end)),
  register(pid_state_machine, spawn(fun() -> state_machine:start() end)),
  register(pid_event_handler, spawn(fun() -> event_handler:start() end)),
  networkManager:start(),
  global_data:start().


start() ->
	  networkManager:start(),
  {ok, Pid_elevator_interface} = elevator_interface:start(),
  register(pid_elevator_interface, Pid_elevator_interface),
  register(pid_data_storage, spawn(fun() -> data_storage:start() end)),
  register(pid_state_machine, spawn(fun() -> state_machine:start() end)),
  register(pid_event_handler, spawn(fun() -> event_handler:start() end)),
  global_data:start().


