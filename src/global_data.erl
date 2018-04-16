-module(global_data).
-export([start/0, add_order/3, remove_order/2, get_orders/0, broadcast_status/0, list_find/2]).

-define(NUMBER_OF_FLOORS, 4).
-record(order, {floor, direction}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The elevators sends their status in the following format:
% {node(), Status}
% Where status is:
% Status = {Number_of_orders, Current_floor, Current_direction}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

start() ->
  register(pid_global_orders, spawn(fun() -> order_queue([]) end)),
  register(pid_other_elevators_handler, spawn(fun() -> other_elevators_handler([]) end)),
  spawn(fun order_syncronizer/0).

other_elevators_handler(Elevators) ->
  receive 
    {add_status, Node, Status} ->
      case list_find(Node, Elevators) of
        false -> io:fwrite(""),
          other_elevators_handler([[Node,Status]] ++ Elevators);
        [Old_status] ->
          % If the node data exists already, delete old status and add new
          other_elevators_handler([[Node,Status]] ++ lists:delete([Node,Old_status],Elevators))
      end;
    {get_status, PID} ->
      PID ! {status, Elevators},
      other_elevators_handler(Elevators)
  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iterates over all live elevators and returns the
% one which has least serving orders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_elevator_with_least_orders() ->
  pid_other_elevators_handler ! {get_status, self()},
  receive
    {status, Elevators} ->
      get_elevator_with_least_orders(?NUMBER_OF_FLOORS * 3, node(), Elevators)
  end.
get_elevator_with_least_orders(_, Node, []) ->
  Node;
get_elevator_with_least_orders(Number, Node, [Head|Tail]) ->
  [New_node,{Num_of_orders,_,_}] = Head,
  case Num_of_orders < Number of
    true -> get_elevator_with_least_orders(Num_of_orders, New_node, Tail);
    false -> get_elevator_with_least_orders(Number, Node, Tail)
  end.

broadcast_status() ->
  pid_order_processor ! {get_status, self()},
  receive 
    {Num_of_orders, Floor, Direction} ->
      lists:foreach(fun(Node) -> 
      {pid_other_elevators_handler, Node} ! {add_status, node(), {Num_of_orders, Floor, Direction}} end, nodes())
  end.

add_order(Floor, Direction, Node) ->
  NewOrder = #order{floor = Floor, direction = Direction},
  io:format("Adding order ...~n"),
  pid_global_orders ! {add_order, NewOrder, Node},
  broadcast_orders().

remove_order(Floor, Direction) ->
  Order = #order{floor = Floor, direction = Direction},
  pid_global_orders ! {remove_order, Order},
  lists:foreach(fun(Node) -> {pid_global_orders, Node} ! {remove_order, Order} end, nodes()).

get_orders() ->
  pid_global_orders ! {get_orders, self()},
  receive
    {orders, Orders} ->
      Orders
    after 500 -> []
  end.

order_queue(Orders) ->
  receive
    {add_order, NewOrder, From_node} ->
      case sets:is_element(NewOrder, sets:from_list(Orders)) of
        false ->
          case From_node == node() of
	        true ->
	          Node = get_elevator_with_least_orders(),
	          {pid_order_processor, Node} ! {order_add, NewOrder#order.floor, NewOrder#order.direction, 1},%   add_order(Order),
            timer:sleep(50),
	          {pid_state_machine, Node} ! {new_order};
	        false -> ok
	      end,
          order_queue(Orders ++ [NewOrder]);
        true ->
          order_queue(Orders)
      end;

    {remove_order, Order} ->
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

order_syncronizer() ->
  timer:sleep(20000),
  broadcast_orders(),
  broadcast_status(),
  order_syncronizer().

list_find (_,[]) ->
    false;
list_find (Search_node, [Elevators|ListTail]) ->
  [Node|Status] = Elevators,
    case ( Node == Search_node ) of
        true    -> Status;
        false   -> list_find(Search_node, ListTail)
    end.




