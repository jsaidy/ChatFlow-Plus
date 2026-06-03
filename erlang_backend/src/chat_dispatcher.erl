-module(chat_dispatcher).
-export([start/0, send_message/3, register_user/3, delivered/1, chat_history/0, list_users/0]).

-record(message, {id, from, to, content, status, timestamp}).

start() ->
    setup_mnesia(),
    register(dispatcher, spawn(fun() -> loop() end)),
    io:format("Chat system started on ~p~n", [node()]),
    ok.

setup_mnesia() ->
    mnesia:start(),
    mnesia:create_table(message, [{attributes, record_info(fields, message)}, {ram_copies, [node()]}]),
    mnesia:create_table(user, [{attributes, [username, pid, node]}, {ram_copies, [node()]}]),
    io:format("Chat database ready~n").

save_message(Id, From, To, Content, Status) ->
    Msg = #message{id=Id, from=From, to=To, content=Content, status=Status, timestamp=erlang:system_time(millisecond)},
    mnesia:activity(transaction, fun() -> mnesia:write(Msg) end).

save_user(Username, Pid, Node) ->
    Row = {user, Username, Pid, Node},
    mnesia:activity(transaction, fun() -> mnesia:write(Row) end).

delete_user(Username) ->
    mnesia:activity(transaction, fun() -> mnesia:delete({user, Username}) end).

load_history() ->
    mnesia:activity(transaction, fun() -> mnesia:match_object(#message{_='_'}) end).

load_users() ->
    mnesia:activity(transaction, fun() -> mnesia:match_object({user, '_', '_', '_'}) end).

chat_history() ->
    History = load_history(),
    io:format("=== Chat History (~p messages) ===~n", [length(History)]),
    [io:format("  ~p: ~s -> ~s: ~s~n", [M#message.id, M#message.from, M#message.to, M#message.content]) || M <- History],
    ok.

list_users() ->
    Users = load_users(),
    io:format("=== Online Users (~p) ===~n", [length(Users)]),
    [io:format("  ~s on ~p~n", [Username, Node]) || {user, Username, _, Node} <- Users],
    ok.

send_message(From, To, Content) ->
    Id = erlang:unique_integer([positive]),
    dispatcher ! {send, Id, From, To, Content},
    {ok, Id}.

register_user(Username, Pid, Node) ->
    dispatcher ! {register, Username, Pid, Node}.

delivered(Id) ->
    dispatcher ! {delivered, Id}.

loop() ->
    receive
        {send, Id, From, To, Content} ->
            io:format("Message ~p from ~s to ~s~n", [Id, From, To]),
            save_message(Id, From, To, Content, sent),
            %% Find user from global Mnesia table
            case mnesia:activity(transaction, fun() -> mnesia:read({user, To}) end) of
                [] ->
                    io:format("User ~s not online~n", [To]);
                [{user, To, Pid, Node}] ->
                    Pid ! {deliver, Id, From, Content},
                    io:format("Message ~p sent to ~s on ~p~n", [Id, To, Node])
            end,
            loop();
        
        {register, Username, Pid, Node} ->
            io:format("User ~s registered on ~p~n", [Username, Node]),
            save_user(Username, Pid, Node),
            loop();
        
        {delivered, Id} ->
            io:format("Message ~p delivered~n", [Id]),
            loop();
        
        {nodeup, Node} ->
            io:format("*** NODE JOINED: ~p ***~n", [Node]),
            loop();
        
        {nodedown, Node} ->
            io:format("*** NODE LEFT: ~p ***~n", [Node]),
            %% Remove users from that node
            Users = load_users(),
            lists:foreach(fun({user, Username, _, Node2}) when Node2 == Node ->
                delete_user(Username)
            end, Users),
            loop();
        
        Other ->
            io:format("Unknown: ~p~n", [Other]),
            loop()
    end.
