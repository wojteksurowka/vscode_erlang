-module(lsp_fun_utils).


-export([get_function_range/1, get_type_range/1]).

-include("lsp_log.hrl").


get_function_range({function, {L, C}, _FnName, _FnArity, Body}) ->
    LastClause = lists:last(Body),
    case get_latest_lc(LastClause) of
        {-1,-1} -> {L,C,L,C};
        {L1,C1} -> {L,C,L1+1,C1}
    end.

get_type_range({attribute, {L, C}, type, {_Type, TypDef,_}}) ->
    case get_latest_lc(TypDef) of
        {-1,-1} -> {L,1,L,1};
        {L1,C1} -> {L,C,L1+1,C1}
    end.

% basic filter to get the latest line/column
get_latest_lc({clause, {L, C}, _, _, Body}) ->
    case Body of
        [] -> {L,C};
        _ -> get_latest_lc(lists:last(Body))
    end;
get_latest_lc({T, {L, C}, _, Args}) when T =:= call orelse T =:= 'case' orelse T =:= record ->
    case Args of
        [] -> {L,C};
        _ -> get_latest_lc(lists:last(Args))
    end;
get_latest_lc({M, {_, _}, _, Args}) when M =:= match orelse M =:= cons orelse M =:= map_field_assoc 
                                    orelse M =:= record_field ->
    get_latest_lc(Args);
get_latest_lc({'try', {_, _}, A1, A2, A3, A4}) ->
    List = A1 ++ A2 ++ A3 ++ A4,
    get_latest_lc(lists:last(List));
get_latest_lc({T, {L, C}, Clauses}=_Other) when T =:= tuple orelse T =:= 'if' orelse T =:= map ->
    case Clauses of
        [] -> {L,C};
        _ -> get_latest_lc(lists:last(Clauses))
    end;
get_latest_lc({type, {L, C}, _Type, TypeDefList}) when is_list(TypeDefList) ->
    case TypeDefList of
        [] -> {L,C};
        _ -> get_latest_lc(lists:last(TypeDefList))
    end;
get_latest_lc({_, {L, C}}=_Other) ->
    %?LOG("get_latest_lc: 0 token: ~p", [_Other]),
    {L,C};
get_latest_lc({_, {L, C}, _}=_Other) ->
    %?LOG("get_latest_lc: 1 token: ~p", [_Other]),
    {L,C};
get_latest_lc({_, {L, C}, _, _}=_Other) ->
    %?LOG("get_latest_lc: 2 token: ~p", [_Other]),
    {L,C};
get_latest_lc({_, {L, C}, _, _, _}=_Other) ->
    %?LOG("get_latest_lc: 3 token: ~p", [_Other]),
    {L,C};
get_latest_lc(_Other) ->
    ?LOG("get_latest_lc: unknown token: ~p", [_Other]),
    {-1,-1}.

