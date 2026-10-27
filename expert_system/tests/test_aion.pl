% AION regression tests.
% Run from the expert_system directory:
%   swipl -q -g run_tests -t halt tests/test_aion.pl
%
% Exit status is non-zero when a test fails (plunit prints the details).

:- use_module(library(plunit)).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(apply)).

:- ensure_loaded('../aion_controller.pl').

all_zones(Zones) :- findall(Z, zone(Z), Zones).

json_of(Goal, Dict) :-
    with_output_to(string(Text), Goal),
    atom_json_dict(Text, Dict, []).

% Cheapest simple path cost found by exhaustive enumeration, independent of A*.
brute_force_cost(Start, Goal, Best) :-
    findall(
        Cost,
        (   simple_path(Start, Goal, [Start], Path),
            route_cost(Path, Cost)
        ),
        Costs
    ),
    Costs \== [],
    min_list(Costs, Best).

% Run Goal with the given medical_cases replaced for a throw-away zone.
with_cases(Critical, Serious, Minor, Goal) :-
    setup_call_cleanup(
        assertz(medical_cases(test_zone, Critical, Serious, Minor)),
        Goal,
        retractall(medical_cases(test_zone, _, _, _))
    ).

:- begin_tests(roads).

test(neighbours_are_unique) :-
    findall(N, neighbour('Downtown', N), Ns),
    msort(Ns, Sorted),
    sort(Ns, Unique),
    Sorted == Unique,
    length(Unique, 3).

test(parallel_roads_use_cheapest_cost) :-
    % West Road costs 14.0, Downtown West Road costs 9.8.
    findall(C, neighbour_cost('Downtown', 'Westend', C), [Cost]),
    abs(Cost - 9.8) < 1.0e-9.

test(route_cost_is_deterministic) :-
    findall(C, route_cost(['Downtown', 'Westend', 'Greenfield'], C), [_]).

test(blocked_roads_are_never_neighbours, [fail]) :-
    neighbour('Northside', 'Lakeside').

test(road_between_is_deterministic) :-
    findall(R, road_between('Downtown', 'Westend', R), [_]).

:- end_tests(roads).

:- begin_tests(astar).

test(matches_exhaustive_search_for_every_zone_pair, [forall((zone(A), zone(B), A \== B))]) :-
    astar(A, B, _Path, Cost),
    brute_force_cost(A, B, Expected),
    abs(Cost - Expected) < 1.0e-9.

test(same_zone_is_a_zero_cost_path) :-
    astar('Midtown', 'Midtown', ['Midtown'], 0).

test(has_exactly_one_solution) :-
    findall(P-C, astar('Riverside', 'Midtown', P, C), [_]).

test(path_starts_and_ends_correctly) :-
    astar('Riverside', 'Oldtown', Path, _),
    Path = ['Riverside' | _],
    last(Path, 'Oldtown').

test(unreachable_goal_fails_and_terminates, [fail]) :-
    isolate_zone('Oldtown', Saved),
    setup_call_cleanup(
        true,
        astar('Riverside', 'Oldtown', _, _),
        restore_roads(Saved)
    ).

test(unknown_zone_fails, [fail]) :-
    astar('Riverside', 'Atlantis', _, _).

isolate_zone(Zone, Saved) :-
    findall(
        road_state(R, F, T, D, S, K),
        (   road_state(R, F, T, D, S, K),
            ( F == Zone ; T == Zone )
        ),
        Saved
    ),
    forall(member(Road, Saved), retract(Road)).

restore_roads(Saved) :-
    forall(member(Road, Saved), assertz(Road)).

:- end_tests(astar).

:- begin_tests(rules).

test(medical_priority_thresholds,
     [forall(member(C-S-M-Expected,
        [ 0-0-0-low,
          0-0-1-medium,
          4-14-0-medium,
          4-15-0-high,
          5-0-0-high,
          9-0-0-high,
          10-0-0-critical,
          12-25-30-critical ]))]) :-
    with_cases(C, S, M, ( medical_priority(test_zone, Got), Got == Expected )).

test(medical_priority_is_deterministic) :-
    with_cases(7, 3, 2, ( findall(P, medical_priority(test_zone, P), [high]) )).

test(population_risk_score_boundaries,
     [forall(member(People-Score, [0-1, 19-1, 20-2, 49-2, 50-3, 99-3, 100-4, 500-4]))]) :-
    findall(S, population_risk_score(People, S), [Score]).

test(each_zone_has_exactly_one_risk_level, [forall(zone(Z))]) :-
    findall(L, zone_risk_level(Z, L), [_]).

test(each_zone_has_exactly_one_evacuation_priority, [forall(zone(Z))]) :-
    findall(L, evacuation_priority(Z, L), [_]).

test(medical_emergency_zone_has_a_single_definition) :-
    findall(F, ( clause(medical_emergency_zone(_), _, Ref), clause_property(Ref, file(F)) ), Files),
    sort(Files, [File]),
    sub_atom(File, _, _, 0, 'response_planner.pl').

:- end_tests(rules).

:- begin_tests(plan).

test(plan_covers_every_zone_once) :-
    generate_complete_plan(Plan),
    all_zones(Zones),
    findall(Z, member(zone_response(zone(Z), _, _), Plan), Planned),
    msort(Planned, SortedPlanned),
    msort(Zones, SortedZones),
    SortedPlanned == SortedZones.

test(plan_is_ordered_by_descending_priority) :-
    generate_complete_plan(Plan),
    findall(
        Score,
        member(zone_response(_, decision(decision(_, _, _, _, priority_score(Score), _, _, _, _, _, _)), _), Plan),
        Scores
    ),
    msort(Scores, Ascending),
    reverse(Ascending, Scores).

test(plan_json_is_valid_and_complete) :-
    json_of(aion_json_result, Dict),
    length(Dict.plan, 10),
    forall(
        member(Z, Dict.plan),
        (   _ = Z.zone,
            _ = Z.decision.action,
            _ = Z.decision.risk.level,
            _ = Z.decision.ambulance.name,
            _ = Z.decision.hospital.available_capacity,
            _ = Z.decision.shelter.route,
            _ = Z.explanation.reasoning.facts.zone_condition.flood_level,
            _ = Z.explanation.reasoning.medical.minor_cases
        )
    ).

test(system_json_has_expected_sections) :-
    json_of(aion_system_json, Dict),
    Dict.metrics.total_zones == 10,
    _ = Dict.disaster.type,
    is_list(Dict.priority_order),
    is_list(Dict.resource_shortages).

test(zone_json_matches_plan_entry, [forall(zone(Z))]) :-
    json_of(aion_zone_response(Z), ZoneDict),
    json_of(aion_json_result, PlanDict),
    atom_string(Z, ZString),
    get_dict(plan, PlanDict, Entries),
    member(Entry, Entries),
    get_dict(zone, Entry, ZString),
    !,
    get_dict(decision, Entry, Decision),
    get_dict(explanation, Entry, Explanation),
    get_dict(decision, ZoneDict, Decision),
    get_dict(explanation, ZoneDict, Explanation).

test(unknown_zone_returns_error_json_instead_of_failing) :-
    json_of(aion_zone_response('Atlantis'), Dict),
    Dict.error == "zone_not_found".

test(explanation_resource_keys_describe_their_values) :-
    json_of(aion_zone_response('Midtown'), Dict),
    H = Dict.explanation.resources.hospital,
    H.available_capacity =< H.capacity,
    is_list(H.route),
    number(H.cost).

test(no_ambulance_is_assigned_to_two_zones) :-
    findall(Name, ( zone_decision(_, decision(_, _, _, _, _, _, ambulance(Name, _, _, _, _, _), _, _, _, _)), Name \== none ), Names),
    msort(Names, Sorted),
    sort(Names, Unique),
    Sorted == Unique,
    Names \== [].

test(hospital_commitments_fit_capacity) :-
    zone_decision(_, _),
    forall(
        committed(hospital, Name, _),
        (   committed_amount(hospital, Name, Used),
            hospital_state(Name, _, _, Available, _, _),
            Used =< Available
        )
    ).

test(shelter_commitments_fit_capacity) :-
    zone_decision(_, _),
    forall(
        committed(shelter, Name, _),
        (   committed_amount(shelter, Name, Used),
            shelter_state(Name, _, _, Available, _),
            Used =< Available
        )
    ).

test(shortages_are_exactly_the_zones_left_without_a_resource) :-
    resource_shortages(Shortages),
    findall(
        shortage(ambulance, Z),
        zone_decision(Z, decision(_, _, _, _, _, _, ambulance(none, _, _, _, _, _), _, _, _, _)),
        Missing
    ),
    forall(member(S, Missing), memberchk(S, Shortages)).

:- end_tests(plan).
