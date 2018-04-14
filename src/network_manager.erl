-module(network_manager).
-export([start/0, name_manager/1]).

-define(RECEIVE_PORT, 20066).
-define(SEND_PORT, 20067).

start() ->
  node_init(),
  spawn(fun listen/0),
  spawn(fun broadcast/0),
  register(test_pid, spawn(fun test_node/0)).

node_init() ->
  os:cmd("epmd -daemon"), % start epmd as daemon in case it's not running
  timer:sleep(100), % give epmd some time to start
  {_ok, [{IPtuple, _Broadcast, _Self} | _Disregard]} = inet:getif(), %fix this (make it more general)
  NodeName = "elevator@"++integer_to_list(element(1,IPtuple))++"."++integer_to_list(element(2,IPtuple))++"."++integer_to_list(element(3,IPtuple))++"."++integer_to_list(element(4,IPtuple)), %how do I program

  register(nameman, spawn(fun() -> name_manager(NodeName) end)),
  net_kernel:start([list_to_atom(NodeName), longnames]),
  erlang:set_cookie(node(), 'robert-og-dino').

listen() ->
  {ok, ReceiveSocket} = gen_udp:open(?RECEIVE_PORT, [list, {active, false}]),
  listen(ReceiveSocket).

listen(ReceiveSocket) ->
  {ok, {_Address, _Port, NodeName}} = gen_udp:recv(ReceiveSocket, 0),
  io:format("NodeName: ~p~n", [NodeName]), %debug
  Node = list_to_atom(NodeName),
  io:format("is member bool: ~p~n", [lists:member(Node, [node()|nodes()])]), %debug

  case Node /= node() of
    true -> {test_pid, Node} ! {test};
    false -> io:format("not me~n")
  end,

  case lists:member(Node, [node()|nodes()]) of
    true ->
      listen(ReceiveSocket);
    false ->
      net_adm:ping(Node), % ping node to create a connection
      io:format("Node connected: ~p~n", [Node]), %debug
      listen(ReceiveSocket)
  end.

broadcast() ->
  {ok, SendSocket} = gen_udp:open(?SEND_PORT, [list, {active, true}, {broadcast, true}]),
  broadcast(SendSocket).

broadcast(SendSocket) ->
  ok = gen_udp:send(SendSocket, {255,255,255,255}, ?RECEIVE_PORT, atom_to_list(node())),
  timer:sleep(7000),
  broadcast(SendSocket).

name_manager(NodeName) ->
  receive {get_name, PID} ->
    PID ! {node_name, NodeName}
  end,
  name_manager(NodeName).


test_node() ->
  receive
    {test} ->
      io:format("node msg works~n")
  end,
  test_node().











