-module(order_handler).
-export([start/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Order setters and getters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
order_storage_add(Floor_nr, Button_type, Status) ->
  ets:insert(button_order_id, {{Floor_nr, Button_type},Status}).
order_storage_getStatus(Floor_nr, Button_type) ->
  Order = ets:lookup(button_order_id, {Floor_nr, Button_type}),
  case Order of
    [] -> 0;
    [H|_] ->
      {{_,_},Status} = H,
      Status
  end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


start() ->
  io:format("Start order handler module ~n"),
  order_storage_init(),
  order_storage_add(0,cab,1),
  order_storage_add(0,cab,3),
  order_storage_add(0,cab,0),
  timer:sleep(500),
  Status = order_storage_getStatus(0,cab),

  io:format(lists:flatten(io_lib:format("~p", [Status]))).



order_storage_init() ->
  ets:new(button_order_id, [set, named_table]).
  %Storage_id = ets:new(orders, [bag]).
  %send storage id periodically, event handler




%order_handler(Storage_id) ->
  %case length(Floor1_orders)
  % case single order
  %update elevator state
  %is_order_handled == true;
  %calculate new order
  %send to fsm


