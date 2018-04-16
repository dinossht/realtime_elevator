%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Credits:
% This code is mostly based on
% Tharald Stray's and Johan Korsnes's
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-module(network_manager).
-export([start/0]).

-define(RECEIVE_PORT, 20066).
-define(SEND_PORT, 20067).

start() ->
  node_init(),
  spawn(fun listen/0),
  spawn(fun broadcast/0).

node_init() ->
  os:cmd("epmd -daemon"),
  timer:sleep(100),

  NodeName = get_unique_node_name(),
  net_kernel:start([list_to_atom(NodeName), longnames]),
  erlang:set_cookie(node(), 'robert-og-dino').

listen() ->
  {ok, ReceiveSocket} = gen_udp:open(?RECEIVE_PORT, [list, {active, false}]),
  listen(ReceiveSocket).
listen(ReceiveSocket) ->
  {ok, {_Address, _Port, NodeName}} = gen_udp:recv(ReceiveSocket, 0),
  %io:format("NodeName: ~p~n", [NodeName]), %debug
  Node = list_to_atom(NodeName),
  %io:format("is member bool: ~p~n", [lists:member(Node, [node()|nodes()])]), %debug
  case nodes() == [] of
    true -> ok;
    false -> io:format("Nodes: ~p~n", nodes())
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Creates unique name based on IP
get_unique_node_name() ->
  {_ok, [{IPtuple, _Broadcast, _Self} | _Disregard]} = inet:getif(), %fix this (make it more general)
  "elevator@"++integer_to_list(element(1,IPtuple))++"."++integer_to_list(element(2,IPtuple))++"."++integer_to_list(element(3,IPtuple))++"."++integer_to_list(element(4,IPtuple)).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%