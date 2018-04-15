-module(global_data).
-record(order, {floor, direction}).

-export([ start/0,
          add_order/2,
          remove_order/2,
          get_orders/1 ]).
%-record(order, {floor, direction}).
-record(status, {floor, direction, state}).

start() ->
  register(global_orderman, spawn(fun() -> order_queue([]) end)),
  %register(all_elevators, spawn(fun() -> other_elevators([]) end)),
  spawn(fun order_synchronizer/0).

%{Node, Floor, Dir, State} <- this format
other_elevators(Elevators) ->
  receive 
    {add_status, Node, Status} -> 
      case listFind(Node, Elevators) of
        false -> io:fwrite("Dette gikk");
        [_,_] -> lists:delete([Node, Status],Elevators)
      end,
      other_elevators([Elevators]++[Node,Status])
  end.

add_order(Floor, Direction) ->
  NewOrder = #order{floor = Floor, direction = Direction},
    GlobalOrders = get_orders(global_orderman),
    case sets:is_element(NewOrder, sets:from_list(GlobalOrders)) of
      false ->
        global_orderman ! {add_order, NewOrder},
        broadcast_orders();
      true ->
        ok
    end.

remove_order(QueueName, Order) ->
  io:format("ORDER MANAGER: remove_order(~p, ~p)~n", [QueueName, Order]),
  {_,Floor,Direction} = Order,
  QueueName ! {remove_order, #order{floor = Floor, direction = Direction}},
  case QueueName of
    orderman ->
      lists:foreach(fun(Node) -> {orderman, Node} ! {remove_order, Order} end, nodes());
    _ -> ok
  end.

get_orders(QueueName) ->
  QueueName ! {get_orders, self()},
  receive
    {orders, Orders} ->
      Orders
    after 500 ->%?RECEIVE_BLOCK_TIME ->
      io:format("~s Order manager waiting for orders in get_orders().~n", [color:red("RECEIVE TIMEOUT:")]),
      []
  end.

order_queue(Orders) ->
  io:format("ORDER MANAGER: Orderlist of: ~p~n", [Orders]), %debug
  receive
    {add_order, NewOrder} ->
      case sets:is_element(NewOrder, sets:from_list(Orders)) of
        false ->
          % TODO: review line below...
          %elev_driver:set_button_lamp(element(2, NewOrder),element(3, NewOrder), on),
          io:fwrite("Add order"),
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
  GlobalOrders = get_orders(global_orderman),

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
order_synchronizer().


listFind ( Element, [] ) ->
    false;

listFind ( Element, [ Elev | ListTail ] ) ->
  [Node|Status] = Elev,
    case ( Node == Elev ) of
        true    ->  
          io:fwrite("Item: ~p",[Elev]),
          Status;
        false   ->  listFind(Element, ListTail)
    end.