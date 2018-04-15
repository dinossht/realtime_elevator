-module(network_manager).
-export([start/1]).

%-define(RECEIVE_PORT, 20050).
%-define(SEND_PORT, 20060).


-define(NODE1_SEND_PORT, 20052).
-define(NODE2_SEND_PORT, 20053).

-define(NODE1_RECV_PORT, 20050).
-define(NODE2_RECV_PORT, 20051).

%name is 'atom'
start(Name) ->
  node_init(Name),
  spawn(fun listen/0),
  spawn(fun broadcast/0).

node_init(Name) ->
  os:cmd("epmd -daemon"), % start epmd as daemon in case it's not running
  timer:sleep(100), % give epmd some time to start

  NodeName = Name,
  net_kernel:start([NodeName, shortnames]),
  erlang:set_cookie(node(), 'hello').

listen() ->
  {ok, ReceiveSocket} = gen_udp:open(?NODE2_RECV_PORT, [list, {active, false}]),
  listen(ReceiveSocket).

listen(ReceiveSocket) ->
  {ok, {_Address, _Port, NodeName}} = gen_udp:recv(ReceiveSocket, 0),
  io:format("NodeName: ~p~n", [NodeName]), %debug
  Node = list_to_atom(NodeName),
  io:format("is member bool: ~p~n", [lists:member(Node, [node()|nodes()])]), %debug

  case lists:member(Node, [node()|nodes()]) of
    true ->
      listen(ReceiveSocket);
    false ->
      net_adm:ping(Node), % ping node to create a connection
      io:format("Node connected: ~p~n", [Node]), %debug
      listen(ReceiveSocket)
  end.

broadcast() ->
  {ok, SendSocket} = gen_udp:open(?NODE2_SEND_PORT, [list, {active, true}, {broadcast, true}]),
  broadcast(SendSocket).

broadcast(SendSocket) ->
  ok = gen_udp:send(SendSocket, {127,0,0,1}, ?NODE1_RECV_PORT, atom_to_list(node())),
  timer:sleep(7000),
  broadcast(SendSocket).