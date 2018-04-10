-module(networkManager).
-export([start/0]).

start() ->
  io:fwrite("Start event manager module\n").
  %register(pid_network_manager, spawn(fun() -> state_init() end)).