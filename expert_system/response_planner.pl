:- ensure_loaded('facts.pl').
:- ensure_loaded('rules.pl').
:- ensure_loaded('search.pl').
:- ensure_loaded('astar.pl').
:- ensure_loaded('resource_engine.pl').
:- ensure_loaded('decision_engine.pl').
:- ensure_loaded('explanation.pl').

% 1. DISASTER INFORMATION
disaster_information(
    Information
) :-
    current_disaster(
        DisasterType,
        Severity
    ),
    Information =
        disaster(
            type(DisasterType),
            severity(Severity)
        ).

% 2. ZONE PRIORITY
zone_priority(
    Zone,
    PriorityScore
) :-
    zone_decision(
        Zone,
        decision(
            Zone,
            _Risk,
            _Medical,
            _Evacuation,
            priority_score(PriorityScore),
            _Action,
            _Ambulance,
            _Hospital,
            _Shelter,
            _Resources,
            _Reason
        )
    ).

% 3. PRIORITY SORTING
make_priority_keys(
    [],
    []
).

make_priority_keys(
    [
        Zone-Priority
        | Rest
    ],
    [
        NegPriority-Zone
        | KeyedRest
    ]
) :-
    NegPriority is -Priority,
    make_priority_keys(
        Rest,
        KeyedRest
    ).

sort_zones_by_priority(
    ZonePriorities,
    SortedZones
) :-
    make_priority_keys(
        ZonePriorities,
        Keyed
    ),
    keysort(
        Keyed,
        SortedKeyed
    ),
    remove_priority_keys(
        SortedKeyed,
        SortedZones
    ).

remove_priority_keys(
    [],
    []
).

remove_priority_keys(
    [
        _Priority-Zone
        | Rest
    ],
    [
        Zone
        | Zones
    ]
) :-
    remove_priority_keys(
        Rest,
        Zones
    ).

% 4. ALL ZONE PRIORITIES
all_zone_priorities(
    Priorities
) :-
    findall(
        Zone-Priority,
        zone_priority(
            Zone,
            Priority
        ),
        Priorities
    ).

% 5. PRIORITIZED ZONES
prioritized_zones(
    Zones
) :-
    all_zone_priorities(
        Priorities
    ),
    sort_zones_by_priority(
        Priorities,
        Zones
    ).

% 6. RESOURCE SHORTAGES
response_resource_shortages(
    Shortages
) :-
    resource_shortages(
        Shortages
    ).

% 7. ZONE RESPONSE
zone_response(
    Zone,
    Response
) :-
    zone_decision(
        Zone,
        Decision
    ),
    zone_explanation(
        Zone,
        Explanation
    ),
    Response =
        zone_response(
            zone(Zone),
            decision(Decision),
            explanation(Explanation)
        ).

% 8. ALL ZONE RESPONSES
all_zone_responses(
    Responses
) :-
    prioritized_zones(
        Zones
    ),
    findall(
        Response,
        (
            member(
                Zone,
                Zones
            ),
            once(
                zone_response(
                    Zone,
                    Response
                )
            )
        ),
        Responses
    ).

% 9. CRITICAL ZONES
critical_zone(
    Zone
) :-
    zone_decision(
        Zone,
        decision(
            Zone,
            risk(critical, _),
            _Medical,
            _Evacuation,
            _Priority,
            _Action,
            _Ambulance,
            _Hospital,
            _Shelter,
            _Resources,
            _Reason
        )
    ).

critical_zones(
    Zones
) :-
    findall(
        Zone,
        critical_zone(Zone),
        Zones
    ).

% 10. MEDICAL EMERGENCY ZONES
medical_emergency_zone(
    Zone
) :-
    zone_decision(
        Zone,
        decision(
            Zone,
            _Risk,
            medical(critical),
            _Evacuation,
            _Priority,
            _Action,
            _Ambulance,
            _Hospital,
            _Shelter,
            _Resources,
            _Reason
        )
    ).

medical_emergency_zones(
    Zones
) :-
    findall(
        Zone,
        medical_emergency_zone(Zone),
        Zones
    ).

% 11. IMMEDIATE ACTION ZONES
immediate_action_zone(
    Zone
) :-
    zone_decision(
        Zone,
        decision(
            Zone,
            _Risk,
            _Medical,
            _Evacuation,
            _Priority,
            action(immediate_evacuation),
            _Ambulance,
            _Hospital,
            _Shelter,
            _Resources,
            _Reason
        )
    ).

immediate_action_zones(
    Zones
) :-
    findall(
        Zone,
        immediate_action_zone(Zone),
        Zones
    ).

% 12. RESOURCE UTILIZATION SUMMARY
response_resource_summary(
    Summary
) :-
    resource_summary(
        Resources
    ),
    Summary =
        response_resources(
            Resources
        ).

% 13. RESPONSE METRICS
response_metrics(
    Metrics
) :-
    findall(
        Zone,
        zone(Zone),
        Zones
    ),
    length(
        Zones,
        TotalZones
    ),
    critical_zones(
        CriticalZones
    ),
    length(
        CriticalZones,
        CriticalCount
    ),
    medical_emergency_zones(
        MedicalZones
    ),
    length(
        MedicalZones,
        MedicalCount
    ),
    immediate_action_zones(
        ImmediateZones
    ),
    length(
        ImmediateZones,
        ImmediateCount
    ),
    resource_shortages(
        Shortages
    ),
    length(
        Shortages,
        ShortageCount
    ),
    Metrics =
        metrics(
            total_zones(TotalZones),
            critical_zones(CriticalCount),
            medical_emergency_zones(MedicalCount),
            immediate_evacuation_zones(ImmediateCount),
            resource_shortages(ShortageCount)
        ).

% 14. OPERATIONAL RESPONSE PLAN
generate_response_plan(
    Plan
) :-
    disaster_information(
        Disaster
    ),
    prioritized_zones(
        PrioritizedZones
    ),
    all_zone_responses(
        ZoneResponses
    ),
    critical_zones(
        CriticalZones
    ),
    medical_emergency_zones(
        MedicalEmergencyZones
    ),
    immediate_action_zones(
        ImmediateActionZones
    ),
    response_resource_shortages(
        Shortages
    ),
    response_resource_summary(
        Resources
    ),
    response_metrics(
        Metrics
    ),
    Plan =
        response_plan(
            disaster(Disaster),
            priority_order(PrioritizedZones),
            critical_zones(CriticalZones),
            medical_emergency_zones(MedicalEmergencyZones),
            immediate_action_zones(ImmediateActionZones),
            resource_shortages(Shortages),
            resources(Resources),
            metrics(Metrics),
            zones(ZoneResponses)
        ).

% 15. RESPONSE PLAN FOR ONE ZONE
generate_zone_plan(
    Zone,
    Plan
) :-
    zone_response(
        Zone,
        Response
    ),
    Plan =
        zone_plan(
            Zone,
            Response
        ).

% 16. PLAN SUMMARY
response_plan_summary(
    Summary
) :-
    response_metrics(
        Metrics
    ),
    prioritized_zones(
        PrioritizedZones
    ),
    Summary =
        plan_summary(
            metrics(Metrics),
            priority_order(PrioritizedZones)
        ).

% 17. PLAN VALIDATION
validate_response_plan(
    Plan,
    valid
) :-
    Plan =
        response_plan(
            _Disaster,
            _PriorityOrder,
            _CriticalZones,
            _MedicalZones,
            _ImmediateZones,
            _Shortages,
            _Resources,
            _Metrics,
            Zones
        ),
    Zones \= [].

validate_response_plan(
    _Plan,
    invalid
).