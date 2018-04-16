-module(network_manager).
-export([start1/0, start2/0]).

%-define(RECEIVE_PORT, 20050).
%-define(SEND_PORT, 20060).


-define(NODE1_SEND_PORT, 20052).
-define(NODE2_SEND_PORT, 20053).

-define(NODE1_RECV_PORT, 20050).
-define(NODE2_RECV_PORT, 20051).

%name is 'atom'
start1() ->
  node_init('n1'),
  spawn(fun() -> listen(7777) end),
  spawn(fun() -> broadcast(6666, 8888) end).

start2() ->
  node_init('n2'),
  spawn(fun() -> listen(8888) end),
  spawn(fun() -> broadcast(5555, 7777) end).

node_init(Name) ->
  os:cmd("epmd -daemon"), % start epmd as daemon in case it's not running
  timer:sleep(100), % give epmd some time to start

  NodeName = Name,
  net_kernel:start([NodeName, shortnames]),
  erlang:set_cookie(node(), 'hello').

listen(PORT1) ->
  {ok, ReceiveSocket} = gen_udp:open(PORT1, [list, {active, false}]),
  listen_(ReceiveSocket).

listen_(ReceiveSocket) ->
  {ok, {_Address, _Port, NodeName}} = gen_udp:recv(ReceiveSocket, 0),
  io:format("NodeName: ~p~n", [NodeName]), %debug
  Node = list_to_atom(NodeName),
  io:format("is member bool: ~p~n", [lists:member(Node, [node()|nodes()])]), %debug

  case lists:member(Node, [node()|nodes()]) of
    true ->
      listen_(ReceiveSocket);
    false ->
      net_adm:ping(Node), % ping node to create a connection
      io:format("Node connected: ~p~n", [Node]), %debug
      listen_(ReceiveSocket)
  end.

broadcast(PORT2, PORT3) ->
  {ok, SendSocket} = gen_udp:open(PORT2, [list, {active, true}, {broadcast, true}]),
  broadcast_(SendSocket, PORT3).

broadcast_(SendSocket, PORT3) ->
  ok = gen_udp:send(SendSocket, {127,0,0,1}, PORT3, atom_to_list(node())),
  timer:sleep(7000),
  broadcast_(SendSocket, PORT3).