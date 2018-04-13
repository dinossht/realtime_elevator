-module(order_processor).
-export([start/0, add_order/2, remove_order/2, get_orders/0]).
-export([test/1, test_request/1, request_above/1, request_below/1]).

-record (order, {floor, direction}).

start() ->
	io:fwrite("Start Order Processor Module\n"),
	%ets:new(orders, [bag, named_table]),
	Orders = [],
	PID = spawn(fun() -> order_stuff(Orders) end),
	register(order_queue,PID). 

add_order(Floor, Direction) ->
	add_order(#order{floor = Floor, direction = Direction}).

add_order(Order) ->
	order_queue ! {add, Order}.

remove_order(Floor, Direction) ->
	remove_order(#order{floor = Floor, direction = Direction}).
remove_order(Order) ->
	order_queue ! {remove, Order}.

get_orders() ->
	order_queue ! {get_orders, ert}. 
test(Value)->
	order_queue ! {testing, Value}.
order_stuff(L) ->
	receive
		{add, Order} ->
			case listFind(Order, L) of
				true -> 
					order_stuff(L);
				false ->
					io:fwrite("i am adding"),
					order_stuff(L++ [Order])
  			end;
  			
  		{remove, Order} ->
  			lists:delete(Order, L),
  			order_stuff(L);

  		{get_orders, PID} ->
  			%PID ! L,
  			io:fwrite("~62p~n",[L]),
  			order_stuff(L);
  		{testing, Value} ->
  			
  			io:fwrite("~62p~n",[lists:keyfind(Value, 2, L)]),
  			order_stuff(L);
  		{request, Floor} ->
  			case request_at_floor(Floor, L) of
  				true -> 
  					io:fwrite("It worked");
  				false ->
  					io:fwrite("no one here")
  			end,
  			order_stuff(L);
  		{request_a, Floor} ->
  			case request_above(Floor, L) of
  				true ->
  					io:fwrite("JADDA!!!");
  				false -> 
  					io:fwrite("NEEEEI")
  			end,
  			order_stuff(L);
  		{request_b, Floor} ->
  			case request_below(Floor, L) of
  				true ->
  					io:fwrite("JADDA!!! below");
  				false -> 
  					io:fwrite("NEEEEI below")
  			end,
  			order_stuff(L)
  	end. 


%order_bag(B) ->
%	receive
%		{add, Order} ->
%  			ets:insert(B, Order),
%  			%io:format(Order),
%  			ets:lookup(B, three),
%  			io:fwrite("i am here"),
%  			order_bag(B);
%  		{show_all_up} ->
%  			A = ets:lookup(B, three),
%  			io:fwrite(A),
%  			order_bag(B)%
%  	end. 
test_request(Floor) ->
	order_queue ! {request, Floor}.

%request_new_direction(Last_direction, Last_floor, PID) ->
request_at_floor(Floor, L) ->
	case lists:keyfind(Floor,2 , L) of 
		{order, Floor, _} -> true;
		false -> false
	end. 
request_above(Floor) -> 
	order_queue ! {request_a, Floor}.

request_above(Floor, L) ->
	case Floor < 4-1 of
		true -> 
			case request_at_floor(Floor+1, L) of
				true -> true;
				false -> request_above(Floor+1, L)
			end;
		false -> false
	end.
request_below(Floor) -> 
	order_queue ! {request_b, Floor}.

request_below(Floor, L) ->
	case Floor > 0  of
		true -> 
			case request_at_floor(Floor-1, L) of
				true -> true;
				false -> request_below(Floor-1, L)
			end;
		false -> false
	end.


listFind ( Element, [] ) ->
    false;

listFind ( Element, [ Item | ListTail ] ) ->
    case ( Item == Element ) of
        true    ->  true;
        false   ->  listFind(Element, ListTail)
    end.