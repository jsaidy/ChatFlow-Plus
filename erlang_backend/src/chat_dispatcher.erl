-module(chat_dispatcher).
-export([start/0, send_message/3, register_user/3, delivered/1, chat_history/0, list_users/0]).

-record(message, {id, from, to, content, status, timestamp}).
-record(user, {username, pid, node}).

start() ->
    setup_mnesia(),
    register(dispatcher, spawn(fun loop/0)),
    io:format("Chat system started on ~p~n", [node()]),
    ok.

setup_mnesia() ->
    mnesia:start(),
    case mnesia:create_table(message, [{attributes, record_info(fields, message)}, {ram_copies, [node()]}]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, _}} -> ok
    end,
    case mnesia:create_table(user, [{attributes, record_info(fields, user)}, {ram_copies, [node()]}]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, _}} -> ok
    end,
    io:format("Chat database ready~n").

save_message(Id, From, To, Content, Status) ->
    Msg = #message{id=Id, from=From, to=To, content=Content, status=Status, timestamp=erlang:system_time(millisecond)},
    mnesia:activity(transaction, fun() -> mnesia:write(Msg) end).

save_user(Username, Pid, Node) ->
    User = #user{username=Username, pid=Pid, node=Node},
    mnesia:activity(transaction, fun() -> mnesia:write(User) end).

delete_user_by_username(Username) ->
    mnesia:activity(transaction, fun() -> mnesia:delete({user, Username}) end).

load_history() ->
    mnesia:activity(transaction, fun() -> mnesia:match_object(#message{_='_'}) end).

load_users() ->
    mnesia:activity(transaction, fun() -> mnesia:match_object(#user{_='_'}) end).

chat_history() ->
    History = load_history(),
    io:format("=== Chat History (~p messages) ===~n", [length(History)]),
    [io:format("  ~p: ~s -> ~s: ~s~n", [M#message.id, M#message.from, M#message.to, M#message.content]) || M <- History],
    ok.

list_users() ->
    Users = load_users(),
    io:format("=== Online Users (~p) ===~n", [length(Users)]),
    [io:format("  ~s on ~p~n", [U#user.username, U#user.node]) || U <- Users],
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
            case mnesia:activity(transaction, fun() -> mnesia:read({user, To}) end) of
                [] ->
                    io:format("User ~s not online~n", [To]);
                [User] ->
                    User#user.pid ! {deliver, Id, From, Content},
                    io:format("Message ~p sent to ~s~n", [Id, To])
            end,
            loop();

        {register, Username, Pid, Node} ->
            io:format("User ~s registered on ~p~n", [Username, Node]),
            save_user(Username, Pid, Node),
            io:format("User ~s saved to Mnesia~n", [Username]),
            loop();

        {delivered, Id} ->
            io:format("Message ~p delivered~n", [Id]),
            loop();

        {nodeup, Node} ->
            io:format("*** NODE JOINED: ~p ***~n", [Node]),
            loop();

        {nodedown, Node} ->
            io:format("*** NODE LEFT: ~p ***~n", [Node]),
            Users = load_users(),
            lists:foreach(
                fun(User) ->
                    if User#user.node == Node ->
                        io:format("Removing user ~s~n", [User#user.username]),
                        delete_user_by_username(User#user.username);
                       true ->
                        ok
                    end
                end,
                Users),
            loop();

        Other ->
            io:format("Unknown: ~p~n", [Other]),
            loop()
    end.
