-module(flare_utils).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    compress/2,
    compression/1,
    send_recv/3,
    topic_key/1
]).

%% public
-spec compress(compression(), iolist()) ->
    iolist().

compress(?COMPRESSION_NONE, Messages) ->
    Messages;
compress(?COMPRESSION_SNAPPY, Messages) ->
    {ok, Messages2} = snappy:compress(Messages),
    Messages2.

-spec compression(compression_name()) ->
    compression().

compression(none) ->
    ?COMPRESSION_NONE;
compression(snappy) ->
    ?COMPRESSION_SNAPPY.

-spec send_recv(inet:socket_address() | inet:hostname(), inet:port_number(),
    iodata()) -> {ok, binary()} | {error, term()}.

send_recv(Ip, Port, Data) ->
    case gen_tcp:connect(Ip, Port, ?SOCKET_OPTIONS ++ [{active, false}]) of
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

-spec topic_key(binary()) ->
    binary().

topic_key(Topic) ->
    binary:replace(Topic, <<".">>, <<"_">>, [global]).
