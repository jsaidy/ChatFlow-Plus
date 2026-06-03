-module(node_monitor).
-export([start/0]).

start() ->
    spawn(fun() -> init() end),
    ok.

init() ->
    net_kernel:monitor_nodes(true, [nodedown_reason]),
    io:format("Node monitor started on ~p~n", [node()]),
    loop().

loop() ->
    receive
        {nodeup, Node, _} ->
            io:format("*** SERVER NODE JOINED: ~p ***~n", [Node]),
            dispatcher ! {nodeup, Node},
            loop();
        {nodedown, Node, _} ->
            io:format("*** SERVER NODE LEFT: ~p ***~n", [Node]),
            dispatcher ! {nodedown, Node},
            loop();
        _ ->
            loop()
    end.
