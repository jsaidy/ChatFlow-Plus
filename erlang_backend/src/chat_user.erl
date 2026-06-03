-module(chat_user).
-export([login/1]).

login(Username) ->
    Pid = spawn(fun() -> online(Username) end),
    timer:sleep(100),
    chat_dispatcher:register_user(Username, Pid, node()),
    io:format("User ~s logged in on ~p~n", [Username, node()]),
    {ok, Pid}.

online(Username) ->
    receive
        {deliver, Id, From, Content} ->
            io:format("*** NEW MESSAGE for ~s from ~s: ~s ***~n", [Username, From, Content]),
            chat_dispatcher:delivered(Id),
            online(Username)
    end.
