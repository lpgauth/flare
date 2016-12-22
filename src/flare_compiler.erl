-module(flare_compiler).
-include("flare_internal.hrl").

-export([
    topic_utils/0
]).

%% public
-spec topic_utils() ->
    ok.

topic_utils() ->
    Topics = ets:tab2list(?ETS_TABLE_TOPIC),
    Forms = topic_utils_forms(Topics),
    compile_and_load_forms(Forms),
    ok.

%% private
compile_and_load_forms(Forms) ->
    {ok, Module, Bin} = compile:forms(Forms, [debug_info]),
    code:purge(Module),
    Filename = atom_to_list(Module) ++ ".erl",
    {module, Module} = code:load_binary(Module, Filename, Bin),
    ok.

topic_utils_forms(Topics) ->
    Module = erl_syntax:attribute(erl_syntax:atom(module),
        [erl_syntax:atom(flare_topic_utils)]),
    ExportList = [erl_syntax:arity_qualifier(erl_syntax:atom(server_name),
        erl_syntax:integer(2))],
    Export = erl_syntax:attribute(erl_syntax:atom(export),
        [erl_syntax:list(ExportList)]),
    Function = erl_syntax:function(erl_syntax:atom(server_name),
        server_name_clauses(Topics)),
    [erl_syntax:revert(X) || X <- [Module, Export, Function]].

server_atom(Topic, Index) ->
    list_to_atom("flare_topic_" ++ binary_to_list(Topic) ++
        "_" ++ integer_to_list(Index)).

server_name_clause(Topic, Index) ->
    TopicBin = binary_to_list(Topic),
    BinaryField = [erl_syntax:binary_field(erl_syntax:string(TopicBin))],
    Var1 = erl_syntax:binary(BinaryField),
    Var2 = erl_syntax:integer(Index),
    Body = erl_syntax:atom(server_atom(Topic, Index)),
    erl_syntax:clause([Var1, Var2], [], [Body]).

server_name_clause_anon() ->
    Var = erl_syntax:variable("_"),
    Body = erl_syntax:atom(undefined),
    erl_syntax:clause([Var, Var], [], [Body]).

server_name_clauses(Topics) ->
    server_name_clauses(Topics, []).

server_name_clauses([], Acc) ->
    Acc ++ [server_name_clause_anon()];
server_name_clauses([{Topic, {_BufferSize, PoolSize}} | T], Acc) ->
    ServerClauses = [server_name_clause(Topic, Index) ||
        Index <- lists:seq(0, PoolSize)],
    server_name_clauses(T, Acc ++ ServerClauses).
