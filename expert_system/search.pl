:- ensure_loaded('facts.pl').

% 1. ROAD STATUS PRIORITY
% Lower value = high priority road
road_status_penalty(open, 0).
road_status_penalty(congested, 3).
road_status_penalty(damaged, 6).
road_status_penalty(blocked, 1000000).

% 2. ROAD RISK PENALTY
road_risk_penalty(low, 0).
road_risk_penalty(medium, 2).
road_risk_penalty(high, 5).

% 3. CHECK WHETHER A ROAD CAN CURRENTLY BE USED
usable_road(
    Road,
    From,
    To
) :-
    road_state(
        Road,
        From,
        To,
        _Distance,
        Status,
        _Risk
    ),
    Status \= blocked.

usable_road(
    Road,
    From,
    To
) :-
    road_state(
        Road,
        To,
        From,
        _Distance,
        Status,
        _Risk
    ),
    Status \= blocked.

% 4. NEIGHBOURING ZONES
% Each neighbouring zone is returned once, even when several parallel roads
% connect the same pair of zones.
neighbour(
    From,
    To
) :-
    setof(
        Next,
        Road^usable_road(
            Road,
            From,
            Next
        ),
        Neighbours
    ),
    member(
        To,
        Neighbours
    ).

% 5. BASIC ROAD DISTANCE
road_base_distance(
    Road,
    Distance
) :-
    road_state(
        Road,
        _From,
        _To,
        Distance,
        _Status,
        _Risk
    ).

% 6. DYNAMIC ROAD COST
dynamic_road_cost(
    Road,
    Cost
) :-
    road_state(
        Road,
        _From,
        _To,
        Distance,
        Status,
        Risk
    ),
    road_status_penalty(
        Status,
        StatusPenalty
    ),
    road_risk_penalty(
        Risk,
        RiskPenalty
    ),
    road_congestion_factor(
        Road,
        CongestionFactor
    ),
    Cost is
        Distance * CongestionFactor
        + StatusPenalty
        + RiskPenalty.

% 7. NEIGHBOUR COST
% Cost of travelling between two neighbouring zones along the cheapest usable
% road connecting them.
neighbour_cost(
    From,
    To,
    Cost
) :-
    neighbour(
        From,
        To
    ),
    road_between(
        From,
        To,
        Road
    ),
    dynamic_road_cost(
        Road,
        Cost
    ).

% 8. ROAD ACCESSIBILITY
accessible_road(
    Road,
    From,
    To
) :-
    road_state(
        Road,
        From,
        To,
        _Distance,
        Status,
        _Risk
    ),
    Status \= blocked.

accessible_road(
    Road,
    From,
    To
) :-
    road_state(
        Road,
        To,
        From,
        _Distance,
        Status,
        _Risk
    ),
    Status \= blocked.

% 9. ROAD CONDITION
road_condition(
    Road,
    Status,
    Risk
) :-
    road_state(
        Road,
        _From,
        _To,
        _Distance,
        Status,
        Risk
    ).

% 10. BFS SEARCH
bfs(
    Start,
    Goal,
    Path
) :-
    bfs_queue(
        [[Start]],
        Goal,
        ReversePath
    ),
    reverse(
        ReversePath,
        Path
    ).

% 11. BFS QUEUE PROCESSING
bfs_queue(
    [[Goal|Rest]|_],
    Goal,
    [Goal|Rest]
).

bfs_queue(
    [[Current|Rest]|Queue],
    Goal,
    Path
) :-
    findall(
        [Next,Current|Rest],
        (
            neighbour(
                Current,
                Next
            ),
            \+ member(
                Next,
                [Current|Rest]
            )
        ),
        NewPaths
    ),
    append(
        Queue,
        NewPaths,
        UpdatedQueue
    ),
    bfs_queue(
        UpdatedQueue,
        Goal,
        Path
    ).

% 12. BFS ROUTE COST
bfs_route_cost(
    Path,
    Cost
) :-
    route_cost(
        Path,
        Cost
    ).

% 13. ROUTE COST
route_cost(
    [],
    0
).

route_cost(
    [_],
    0
).

route_cost(
    [From,To|Rest],
    TotalCost
) :-
    neighbour_cost(
        From,
        To,
        Cost
    ),
    route_cost(
        [To|Rest],
        RemainingCost
    ),
    TotalCost is
        Cost + RemainingCost.

% 14. ROUTE DISTANCE
route_distance(
    [],
    0
).

route_distance(
    [_],
    0
).

route_distance(
    [From,To|Rest],
    TotalDistance
) :-
    physical_road_distance(
        From,
        To,
        Distance
    ),
    route_distance(
        [To|Rest],
        RemainingDistance
    ),
    TotalDistance is
        Distance + RemainingDistance.

physical_road_distance(
    From,
    To,
    Distance
) :-
    road_between(
        From,
        To,
        Road
    ),
    road_base_distance(
        Road,
        Distance
    ).

% 15. ROUTE RISK
route_risk(
    [],
    low
).

route_risk(
    [_],
    low
).

route_risk(
    [From,To|Rest],
    Risk
) :-
    road_between(
        From,
        To,
        Road
    ),
    road_condition(
        Road,
        _Status,
        CurrentRisk
    ),
    route_risk(
        [To|Rest],
        RemainingRisk
    ),
    highest_risk(
        CurrentRisk,
        RemainingRisk,
        Risk
    ).

% 16. ROAD BETWEEN TWO ZONES
% The cheapest usable road joining the two zones (deterministic).
road_between(
    From,
    To,
    Road
) :-
    findall(
        Cost-Candidate,
        (
            usable_road(
                Candidate,
                From,
                To
            ),
            dynamic_road_cost(
                Candidate,
                Cost
            )
        ),
        Candidates
    ),
    keysort(
        Candidates,
        [
            _Cost-Road
            | _
        ]
    ).

% 17. RISK COMPARISON
highest_risk(
    low,
    low,
    low
).

highest_risk(
    low,
    medium,
    medium
).

highest_risk(
    low,
    high,
    high
).

highest_risk(
    medium,
    low,
    medium
).

highest_risk(
    medium,
    medium,
    medium
).

highest_risk(
    medium,
    high,
    high
).

highest_risk(
    high,
    low,
    high
).

highest_risk(
    high,
    medium,
    high
).

highest_risk(
    high,
    high,
    high
).

% 18. FIND A ROUTE
find_route(
    Start,
    Goal,
    Path,
    Cost
) :-
    bfs(
        Start,
        Goal,
        Path
    ),
    route_cost(
        Path,
        Cost
    ).

% 19. CHECK WHETHER A ROUTE EXISTS
route_exists(
    Start,
    Goal
) :-
    bfs(
        Start,
        Goal,
        _Path
    ).

% 20. FIND ALTERNATIVE ROUTES
alternative_routes(
    Start,
    Goal,
    Routes
) :-
    findall(
        Path,
        simple_path(
            Start,
            Goal,
            [Start],
            Path
        ),
        RawRoutes
    ),
    remove_duplicate_routes(
        RawRoutes,
        Routes
    ).

% 21. SIMPLE PATH SEARCH
simple_path(
    Goal,
    Goal,
    _Visited,
    [Goal]
).

simple_path(
    Current,
    Goal,
    Visited,
    [Current|Path]
) :-
    neighbour(
        Current,
        Next
    ),
    \+ member(
        Next,
        Visited
    ),
    simple_path(
        Next,
        Goal,
        [Next|Visited],
        Path
    ).

% 22. REMOVE DUPLICATE ROUTES
remove_duplicate_routes(
    Routes,
    UniqueRoutes
) :-
    sort(
        Routes,
        UniqueRoutes
    ).

% 23. ROUTE EVALUATION
evaluate_route(
    Start,
    Goal,
    Path,
    Evaluation
) :-
    bfs(
        Start,
        Goal,
        Path
    ),
    route_cost(
        Path,
        Cost
    ),
    route_distance(
        Path,
        Distance
    ),
    route_risk(
        Path,
        Risk
    ),
    Evaluation =
        route_evaluation(
            Path,
            Cost,
            Distance,
            Risk
        ).

% 24. BEST ROUTE FROM GENERATED ALTERNATIVES
best_route(
    Start,
    Goal,
    BestEvaluation
) :-
    alternative_routes(
        Start,
        Goal,
        Routes
    ),
    findall(
        Cost-Evaluation,
        (
            member(
                Path,
                Routes
            ),
            route_cost(
                Path,
                Cost
            ),
            route_distance(
                Path,
                Distance
            ),
            route_risk(
                Path,
                Risk
            ),
            Evaluation =
                route_evaluation(
                    Path,
                    Cost,
                    Distance,
                    Risk
                )
        ),
        Evaluations
    ),
    Evaluations \= [],
    keysort(
        Evaluations,
        [
            _BestCost-BestEvaluation
            | _
        ]
    ).

% 25. ROUTE SAFETY CHECK
safe_route(
    Path
) :-
    route_risk(
        Path,
        Risk
    ),
    Risk \= high.

% 26. ROUTE STATUS SUMMARY
route_status(
    Path,
    safe
) :-
    safe_route(
        Path
    ).

route_status(
    Path,
    risky
) :-
    route_risk(
        Path,
        high
    ).

% 27. ROAD NETWORK SUMMARY
road_network_summary(
    Summary
) :-
    findall(
        road_info(
            Road,
            From,
            To,
            Distance,
            Status,
            Risk,
            Cost
        ),
        (
            road_state(
                Road,
                From,
                To,
                Distance,
                Status,
                Risk
            ),
            dynamic_road_cost(
                Road,
                Cost
            )
        ),
        Summary
    ).