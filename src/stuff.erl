-module(stuff).

-export([ordersForNod/3, recursiveShit/4, whoHasFewestOrders/0]).

ordersForNod( Search_node, [], Number ) ->
    Number;

ordersForNod( Search_node, [ Item | ListTail ], Number ) ->
  
  %io:fwrite("Element: ~p.  Elev: ~p.  ListTail: ~p.",[Element,Elev,ListTail]),
  {order, Floor, Button_type, Node} = Item,
    case ( Node == Search_node ) of
        true    ->  
          ordersForNod(Search_node, ListTail, Number+1);
        false   ->  ordersForNod(Search_node, ListTail, Number)
    end.

whoHasFewestOrders() ->
	Orders = global_data:get_orders(),
	recursiveShit(Orders, self(), 0, nodes()).

recursiveShit(Orders, Node, Number, []) ->
	Node;
recursiveShit(Orders, Node, Number, [Head|Tails]) ->
	io:fwrite("Node = ~p.  Number: ~p~n", [Node,Number]),
	io:fwrite("Head: ~p.   Tails: ~p~n",[Head,Tails]),
	NewNumber = ordersForNod(Head, Orders, 0),
	case Number < NewNumber of
		true -> recursiveShit(Orders, Node, Number, Tails);
		false -> recursiveShit(Orders, Head, NewNumber, Tails)
	end.