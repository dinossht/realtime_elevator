-module(global_data).
-record(order, {floor, direction}).

-export([ start/0,
          add_order/2,
          remove_order/2,
          get_orders/0,
          broadcast_status/0,
          listFind/2]).
%-record(status, {floor, direction, state}).

start() ->
  register(global_orderman, spawn(fun() -> order_queue([]) end)),
  register(all_elevators, spawn(fun() -> other_elevators([]) end)),
  spawn(fun order_synchronizer/0).

%{Node, Floor, Dir, State} <- this format
other_elevators(Elevators) ->
  receive 
    {add_status, Node, Status} -> 
      case Elevators of
        [] -> io:fwrite("tom liste");
      _ -> io:fwrite("Elevators: ~p",[Elevators])
      end,
      io:fwrite("Hva er dette? ~p~n",[Status]),
      case listFind(Node, Elevators) of
        false -> io:fwrite("Dette gikk ~n"),
          case Elevators of
            [] -> io:fwrite("tom liste");
            _ -> io:fwrite("Elevators: ~p",[Elevators])
          end,
          other_elevators([[Node,Status]] ++ Elevators);
        [OldStatus] -> 
          other_elevators([[Node,Status]] ++ lists:delete([Node,OldStatus],Elevators))
      end;
    {get_status, PID} ->
      PID ! {status, Elevators},
      other_elevators(Elevators)
  end.

broadcast_status() ->
  io:format("broadcast status!~n"),
  pid_data_storage ! {get_status, self()},
  receive 
    {Floor, Direction} ->
      io:format("Floor~p  Dir ~p~n", [Floor, Direction]),
      lists:foreach(fun(Node) -> 
      {all_elevators, Node} ! {add_status, node(), {Floor, Direction}} end, nodes())
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


add_order(Floor, Direction) ->
  NewOrder = #order{floor = Floor, direction = Direction},
  %GlobalOrders = get_orders_(),
  %case sets:is_element(NewOrder, sets:from_list(GlobalOrders)) of
  %  false ->
  io:format("Adding order~n"),
      global_orderman ! {add_order, NewOrder},
      broadcast_orders().
  %  true ->
  %    ok
  %end.


remove_order(Floor, Direction) ->
  Order = #order{floor = Floor, direction = Direction},
%  global_orderman ! {remove_order, #order{floor = Floor, direction = Direction, order_status = Order_status}},
  global_orderman ! {remove_order, Order},
  lists:foreach(fun(Node) -> {global_orderman, Node} ! {remove_order, Order} end, nodes()).


get_orders() ->
  global_orderman ! {get_orders, self()},
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
  io:format("ORDER MANAGER: Orderlist of: ~p~n", [Orders]), %debug
  receive
    {add_order, NewOrder} ->
      case sets:is_element(NewOrder, sets:from_list(Orders)) of
        false ->
          % TODO: review line below...
          %elev_driver:set_button_lamp(element(2, NewOrder),element(3, NewOrder), on),
          %io:fwrite("Add order"),
          %Node = stuff:whoHasFewestOrders(),
          %{pid_data_storage, Node} ! {order_add, NewOrder#order.floor, NewOrder#order.direction, 1},%   add_order(Order),
          order_queue(Orders ++ [NewOrder]);
        true ->
          order_queue(Orders)
      end;

    {remove_order, Order} ->
      io:format("ORDER MANAGER: ACTUALLY removing order.~n"),
      order_queue(Orders--[Order]);

    {get_orders, PID} ->
      PID ! {orders, Orders},
      order_queue(Orders)
  end.

broadcast_orders() ->
  io:format("broadcast broadcast!~n"),
  GlobalOrders = get_orders(),

  lists:foreach(fun(Node) ->
    lists:foreach(fun(Order) -> {global_orderman, Node} ! {add_order, Order} end, GlobalOrders)
  end, nodes()).

broadcast_orders(OrderList) ->
  io:format("ORDER MANAGER: broadcasting orderlist: ~p~n", [OrderList]),
  lists:foreach(fun(Node) ->
    lists:foreach(fun(Order) -> {global_orderman, Node} ! {add_order, Order} end, OrderList)
  end, nodes()).

order_synchronizer() ->
  timer:sleep(20000),
  broadcast_orders(),
  broadcast_status(),
order_synchronizer().


listFind ( Element, [] ) ->
    false;

listFind ( Element, [ Elev | ListTail ] ) ->
  io:fwrite("Element: ~p.  Elev: ~p.  ListTail: ~p.",[Element,Elev,ListTail]),
  [Node|Status] = Elev,
    case ( Node == Element ) of
        true    ->  
          io:fwrite("Item: ~p",[Elev]),
          Status;
        false   ->  listFind(Element, ListTail)
    end.


findOrder ( Element, [] ) ->
    false;

findOrder ( Element, [ Elev | ListTail ] ) ->
  io:fwrite("Element: ~p.  Elev: ~p.  ListTail: ~p.",[Element,Elev,ListTail]),
  [Node|Status] = Elev,
    case ( Node == Element ) of
        true    ->  
          io:fwrite("Item: ~p",[Elev]),
          Status;
        false   ->  listFind(Element, ListTail)
    end.


-ifdef (comment1).
remove_order(Floor, Direction) ->
  remove_order(Floor, Direction, 3).
remove_order(Floor, Direction, Order_status) ->
  Order = #order{floor = Floor, direction = Direction, order_status = Order_status},
%  global_orderman ! {remove_order, #order{floor = Floor, direction = Direction, order_status = Order_status}},
  global_orderman ! {remove_order, Order},
  lists:foreach(fun(Node) -> {global_orderman, Node} ! {remove_order, Order} end, nodes()),

  case Order_status of
    0 -> ok;
    _ -> remove_order(Floor, Direction, Order_status - 1)
  end.

remove_order(Order) ->
  io:format("ORDER MANAGER: remove_order(~p, ~p)~n", [global_orderman, Order]),
  %{_,Floor,Direction,Order_status} = Order,
  %global_orderman ! {remove_order, #order{floor = Floor, direction = Direction, order_status = Order_status}},
  global_orderman ! {remove_order, Order},
  lists:foreach(fun(Node) -> {global_orderman, Node} ! {remove_order, Order} end, nodes()).

-endif.


-ifdef(comment3).
add_order(Floor, Direction, Order_status) ->
  NewOrder = #order{floor = Floor, direction = Direction, order_status = Order_status},
  GlobalOrders = get_orders(),
  case sets:is_element(NewOrder, sets:from_list(GlobalOrders)) of
    false ->
      global_orderman ! {add_order, NewOrder},
      broadcast_orders();
    true ->
      ok
  end.

-endif.
