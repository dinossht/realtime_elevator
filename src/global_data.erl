-module(global_data).
-record(order, {floor, direction}).

-export([start/0, add_order/3, remove_order/2, get_orders/0, broadcast_status/0, listFind/2, get_elevator_with_least_orders/0]).

start() ->
  register(pid_global_orders, spawn(fun() -> order_queue([]) end)),
  register(all_elevators, spawn(fun() -> other_elevators([]) end)),
  spawn(fun order_synchronizer/0).

other_elevators(Elevators) ->
  receive 
    {add_status, Node, Status} -> 
      case Elevators of
        [] -> io:fwrite("");
      _ -> io:fwrite("Elevators: ~p",[Elevators])
      end,
      case listFind(Node, Elevators) of
        false -> io:fwrite("Dette gikk ~n"),
          case Elevators of
            [] -> io:fwrite("");
            _ -> io:fwrite("Elevators: ~p~n",[Elevators])
          end,
          other_elevators([[Node,Status]] ++ Elevators);
        [OldStatus] -> 
          other_elevators([[Node,Status]] ++ lists:delete([Node,OldStatus],Elevators))
      end;
    {get_status, PID} ->
      PID ! {status, Elevators},
      other_elevators(Elevators)
  end.

get_elevator_with_least_orders() ->
  all_elevators ! {get_status, self()},

  receive
    {status, Elevators} ->
      recursiveShit(10, node(),Elevators)
  end.
  

recursiveShit(_, Node, []) ->
  Node;
recursiveShit(Number, Node, [Head|Tail]) ->
  [New_node, {Num_of_orders, _, _}] = Head,
  case Num_of_orders < Number of
    true -> recursiveShit(Num_of_orders, New_node, Tail);
    false -> recursiveShit(Number, Node, Tail)
  end.


broadcast_status() ->
  %io:format("broadcast status!~n"),
  pid_order_processor ! {get_status, self()},
  receive 
    {Num_of_orders, Floor, Direction} ->
      %io:format("Floor~p  Dir ~p~n", [Floor, Direction]),
      lists:foreach(fun(Node) -> 
      {all_elevators, Node} ! {add_status, node(), {Num_of_orders, Floor, Direction}} end, nodes())
  end.

%broadcast_orders(OrderList) ->
%  io:format("ORDER MANAGER: broadcasting orderlist: ~p~n", [OrderList]),
%  lists:foreach(fun(Node) ->
%    lists:foreach(fun(Order) -> {global_orderman, Node} ! {add_order, Order} end, OrderList)
%  end, nodes()).
%
%status_synchronizer() ->
%  timer:sleep(20000),
%  broadcast_status(),
%status_synchronizer().


add_order(Floor, Direction, Node) ->
  NewOrder = #order{floor = Floor, direction = Direction},
  %GlobalOrders = get_orders_(),
  %case sets:is_element(NewOrder, sets:from_list(GlobalOrders)) of
  %  false ->
  io:format("Adding order~n"),
      pid_global_orders ! {add_order, NewOrder, Node},
      broadcast_orders().
  %  true ->
  %    ok
  %end.


remove_order(Floor, Direction) ->
  Order = #order{floor = Floor, direction = Direction},
  pid_global_orders ! {remove_order, Order},
  lists:foreach(fun(Node) -> {pid_global_orders, Node} ! {remove_order, Order} end, nodes()).


get_orders() ->
  pid_global_orders ! {get_orders, self()},
  receive
    {orders, Orders} ->
      Orders
    after 500 ->%?RECEIVE_BLOCK_TIME ->
      %io:format("~s Order manager waiting for orders in get_orders().~n", [color:red("RECEIVE TIMEOUT:")]),
      []
  end.

order_queue(Orders) ->
  case Orders of
    [] -> io:fwrite("tom liste");
    _ -> io:fwrite("Elevators orders in order_queue: ~p~n",[Orders])
  end,
  %io:format("ORDER MANAGER: Orderlist of: ~p~n", [Orders]), %debug
  receive
    {add_order, NewOrder, From_node} ->
      case sets:is_element(NewOrder, sets:from_list(Orders)) of
        false ->
          % TODO: review line below...
          %elev_driver:set_button_lamp(element(2, NewOrder),element(3, NewOrder), on),
          %io:fwrite("Add order"),
          case From_node == node() of
	        true ->
	          Node = get_elevator_with_least_orders(),
	          io:format("I am running...~n"),
	          {pid_order_processor, Node} ! {order_add, NewOrder#order.floor, NewOrder#order.direction, 1},%   add_order(Order),
	          {pid_state_machine, Node} ! {new_order};
	        false -> ok
	      end,
          order_queue(Orders ++ [NewOrder]);
        true ->
          order_queue(Orders)
      end;

    {remove_order, Order} ->
      %io:format("ORDER MANAGER: ACTUALLY removing order.~n"),
      order_queue(Orders--[Order]);

    {get_orders, PID} ->
      PID ! {orders, Orders},
      order_queue(Orders)
  end.

broadcast_orders() ->
  GlobalOrders = get_orders(),

  lists:foreach(fun(Node) ->
    lists:foreach(fun(Order) -> {pid_global_orders, Node} ! {add_order, Order, node()} end, GlobalOrders)
  end, nodes()).

broadcast_orders(OrderList) ->
  lists:foreach(fun(Node) ->
    lists:foreach(fun(Order) -> {pid_global_orders, Node} ! {add_order, Order, node()} end, OrderList)
  end, nodes()).

order_synchronizer() ->
  timer:sleep(20000),
  broadcast_orders(),
  broadcast_status(),
order_synchronizer().


listFind ( Element, [] ) ->
    false;

listFind ( Element, [ Elev | ListTail ] ) ->
  %io:fwrite("Element: ~p.  Elev: ~p.  ListTail: ~p.",[Element,Elev,ListTail]),
  [Node|Status] = Elev,
    case ( Node == Element ) of
        true    ->  
          %io:fwrite("Item: ~p",[Elev]),
          Status;
        false   ->  listFind(Element, ListTail)
    end.


findOrder ( Element, [] ) ->
    false;

findOrder ( Element, [ Elev | ListTail ] ) ->
  %io:fwrite("Element: ~p.  Elev: ~p.  ListTail: ~p.",[Element,Elev,ListTail]),
  [Node|Status] = Elev,
    case ( Node == Element ) of
        true    ->  
          %io:fwrite("Item: ~p",[Elev]),
          Status;
        false   ->  listFind(Element, ListTail)
    end.



