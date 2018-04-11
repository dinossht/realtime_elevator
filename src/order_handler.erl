-module(order_handler).
-export([start/0]).

start() ->
  io:format("Start order handler module ~n"),
  order_storage_init().


order_storage_init() ->
  Storage_id = ets:new(orders, [bag]).
  %send storage id periodically, event handler

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Order setters and getters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
order_storage_add(Storage_id, Floor_nr, Button_type) ->
  ets:insert(Storage_id, {Floor_nr, Button_type}).
order_storage_getStatus(Storage_id, Floor_nr, Button_type) ->
  Orders = ets:lookup(Storage_id, Floor_nr),
  lists:member({Floor_nr, Button_type}, Orders). %returns true or false


order_handler() ->
  %update elevator state
  %is_order_handled == true;
  %calculate new order
  %send to fsm


