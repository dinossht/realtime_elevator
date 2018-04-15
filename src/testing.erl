-module(testing).

-export([listFind/2]).

listFind ( Element, [] ) ->
    false;

listFind ( Element, [ Item | ListTail ] ) ->
	[Node|Status] = Item,
    case ( Node == Element ) of
        true    ->  
        	%io:fwrite("Item: ~p",[Item]),
        	Status;
        false   ->  listFind(Element, ListTail)
    end.	