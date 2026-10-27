:- ensure_loaded('search.pl').
:- ensure_loaded('facts.pl').

% 1. MANHATTAN DISTANCE HEURISTIC
% H(n) estimates the remaining distance between the current zone and the destination.
heuristic(
    Node,
    Goal,
    H
) :-
    coordinates(
        Node,
        X1,
        Y1
    ),
    coordinates(
        Goal,
        X2,
        Y2
    ),
    H is
        abs(X1 - X2)
        +
        abs(Y1 - Y2).

% 2. A* ENTRY POINT
astar(
    Start,
    Goal,
    Path
) :-
    astar(
        Start,
        Goal,
        Path,
        _Cost
    ).

% 3. A* WITH COST
astar(
    Start,
    Goal,
    Path,
    Cost
) :-
    heuristic(
        Start,
        Goal,
        H
    ),
    astar_search(
        [
            node(
                Start,
                [Start],
                0,
                H
            )
        ],
        Goal,
        ReversePath,
        Cost
    ),
    reverse(
        ReversePath,
        Path
    ).

% 4. A* SEARCH LOOP
astar_search(
    [
        node(
            Goal,
            Path,
            Cost,
            _F
        )
        | _
    ],
    Goal,
    Path,
    Cost
) :-
    !.

astar_search(
    [
        node(
            Current,
            Path,
            G,
            _F
        )
        | Open
    ],
    Goal,
    ResultPath,
    ResultCost
) :-
    findall(
        node(
            Next,
            [Next|Path],
            NewG,
            F
        ),
        (
            neighbour_cost(
                Current,
                Next,
                StepCost
            ),
            \+ member(
                Next,
                Path
            ),
            NewG is
                G + StepCost,
            heuristic(
                Next,
                Goal,
                H
            ),
            F is
                NewG + H
        ),
        NewNodes
    ),
    append(
        Open,
        NewNodes,
        UpdatedOpen
    ),
    sort_open_list(
        UpdatedOpen,
        SortedOpen
    ),
    astar_search(
        SortedOpen,
        Goal,
        ResultPath,
        ResultCost
    ).

% 5. SORT OPEN LIST
sort_open_list(
    Nodes,
    Sorted
) :-
    map_nodes_to_keys(
        Nodes,
        Keyed
    ),
    keysort(
        Keyed,
        SortedKeyed
    ),
    remove_node_keys(
        SortedKeyed,
        Sorted
    ).

% 6. MAP NODES TO F-SCORE KEYS
map_nodes_to_keys(
    [],
    []
).

map_nodes_to_keys(
    [
        node(
            Node,
            Path,
            G,
            F
        )
        | Rest
    ],
    [
        F-node(
            Node,
            Path,
            G,
            F
        )
        | KeyedRest
    ]
) :-
    map_nodes_to_keys(
        Rest,
        KeyedRest
    ).

% 7. REMOVE SORT KEYS
remove_node_keys(
    [],
    []
).

remove_node_keys(
    [
        _Key-Node
        | Rest
    ],
    [
        Node
        | Nodes
    ]
) :-
    remove_node_keys(
        Rest,
        Nodes
    ).

% 8. EVALUATE AN A* ROUTE
evaluate_astar_route(
    Start,
    Goal,
    Evaluation
) :-
    astar(
        Start,
        Goal,
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
    route_status(
        Path,
        Status
    ),
    Evaluation =
        route_evaluation(
            Path,
            Cost,
            Distance,
            Risk,
            Status
        ).

% 9. FIND PRIMARY ROUTE
primary_route(
    Start,
    Goal,
    Route
) :-
    evaluate_astar_route(
        Start,
        Goal,
        Route
    ).

% 10. FIND ALTERNATIVE ROUTES
find_route_options(
    Start,
    Goal,
    Options
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
            route_status(
                Path,
                Status
            ),
            Evaluation =
                route_evaluation(
                    Path,
                    Cost,
                    Distance,
                    Risk,
                    Status
                )
        ),
        Evaluations
    ),
    keysort(
        Evaluations,
        Sorted
    ),
    remove_route_keys(
        Sorted,
        Options
    ).

% 11. REMOVE ROUTE SORT KEYS
remove_route_keys(
    [],
    []
).

remove_route_keys(
    [
        _Cost-Evaluation
        | Rest
    ],
    [
        Evaluation
        | Evaluations
    ]
) :-
    remove_route_keys(
        Rest,
        Evaluations
    ).

% 12. BEST ROUTE FROM OPTIONS
best_route_option(
    Start,
    Goal,
    Best
) :-
    find_route_options(
        Start,
        Goal,
        [
            Best
            | _
        ]
    ).

% 13. BACKUP ROUTE
backup_route(
    Start,
    Goal,
    Backup
) :-
    find_route_options(
        Start,
        Goal,
        [
            _Primary,
            Backup
            | _
        ]
    ).

% 14. SAFE PRIMARY ROUTE
safe_primary_route(
    Start,
    Goal,
    Evaluation
) :-
    find_route_options(
        Start,
        Goal,
        Options
    ),
    member(
        Evaluation,
        Options
    ),
    Evaluation =
        route_evaluation(
            _Path,
            _Cost,
            _Distance,
            Risk,
            _Status
        ),
    Risk \= high,
    !.

% 15. ROUTE COMPARISON
compare_routes(
    RouteA,
    RouteB,
    Result
) :-
    RouteA =
        route_evaluation(
            _PathA,
            CostA,
            DistanceA,
            RiskA,
            _StatusA
        ),
    RouteB =
        route_evaluation(
            _PathB,
            CostB,
            DistanceB,
            RiskB,
            _StatusB
        ),
    (
        CostA < CostB
    ->
        Result = first_route_preferred
    ;
        CostA > CostB
    ->
        Result = second_route_preferred
    ;
        DistanceA < DistanceB
    ->
        Result = first_route_preferred
    ;
        DistanceA > DistanceB
    ->
        Result = second_route_preferred
    ;
        RiskA = low,
        RiskB \= low
    ->
        Result = first_route_preferred
    ;
        RiskB = low,
        RiskA \= low
    ->
        Result = second_route_preferred
    ;
        Result = equivalent_routes
    ).

% 16. ROUTE EXPLANATION DATA
route_explanation(
    Start,
    Goal,
    Explanation
) :-
    astar(
        Start,
        Goal,
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
    route_status(
        Path,
        Status
    ),
    Explanation =
        [
            start(Start),
            destination(Goal),
            route(Path),
            route_cost(Cost),
            route_distance(Distance),
            route_risk(Risk),
            route_status(Status),
            routing_method(a_star),
            reason(
                'Route selected using dynamic emergency travel cost and A* search'
            )
        ].

% 17. ROUTE AVAILABILITY CHECK
route_available(
    Start,
    Goal
) :-
    astar(
        Start,
        Goal,
        _Path,
        _Cost
    ).

% 18. NO ROUTE CHECK
no_route_available(
    Start,
    Goal
) :-
    \+
    route_available(
        Start,
        Goal
    ).

% 19. ROUTE METRICS
route_metrics(
    Start,
    Goal,
    Metrics
) :-
    astar(
        Start,
        Goal,
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
    Metrics =
        metrics(
            path(Path),
            distance(Distance),
            cost(Cost),
            risk(Risk)
        ).

% 20. A* SEARCH SUMMARY
astar_summary(
    Start,
    Goal,
    Summary
) :-
    (
        evaluate_astar_route(
            Start,
            Goal,
            Evaluation
        )
    ->
        Summary =
            astar_result(
                success,
                Evaluation
            )
    ;
        Summary =
            astar_result(
                failure,
                no_route
            )
    ).