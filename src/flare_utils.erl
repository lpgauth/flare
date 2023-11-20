-module(flare_utils).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    msg/4,
    send_recv/3,
    timestamp/0
]).

%% public
-spec msg(timestamp(), key(), value(), headers()) ->
    {msg(), non_neg_integer()}.

msg(Timestamp, Key, Value, Headers) ->
    Msg = #{
        ts => Timestamp,
        key => Key,
        value => Value,
        headers => Headers
    },
    Size = size_of_msg(Key, Value, Headers),
    {Msg, Size}.

-spec send_recv(inet:socket_address() | inet:hostname(), inet:port_number(),
    iodata()) -> {ok, binary()} | {error, term()}.

send_recv(Ip, Port, Data) ->
    case gen_tcp:connect(Ip, Port, ?SOCKET_OPTIONS ++ [{active, false}], ?TIMEOUT) of
        {ok, Socket} ->
            case gen_tcp:send(Socket, Data) of
                ok ->
                    case gen_tcp:recv(Socket, 0, ?TIMEOUT) of
                        {ok, Data2} ->
                            gen_tcp:close(Socket),
                            {ok, Data2};
                        {error, Reason} ->
                            error_logger:error_msg("failed to recv: ~p~n",
                                [Reason]),
                            gen_tcp:close(Socket),
                            {error, Reason}
                    end;
                {error, Reason} ->
                    error_logger:error_msg("failed to send: ~p~n", [Reason]),
                    gen_tcp:close(Socket),
                    {error, Reason}
            end;
        {error, Reason} ->
            error_logger:error_msg("failed to connect: ~p~n", [Reason]),
            {error, Reason}
    end.

-spec timestamp() ->
    timestamp().

timestamp() ->
    os:system_time(millisecond).

% private
ssize(undefined) ->
    0;
ssize(Bin) when is_binary(Bin) ->
    size(Bin).

size_of_headers([]) ->
    0;
size_of_headers([{Key, Value} | T]) ->
    ssize(Key) + ssize(Value) + size_of_headers(T).

size_of_msg(Key, Value, Headers) ->
    ssize(Key) + ssize(Value) + size_of_headers(Headers).