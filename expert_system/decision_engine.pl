:- ensure_loaded('rules.pl').
:- ensure_loaded('resource_engine.pl').
:- ensure_loaded('search.pl').
:- ensure_loaded('astar.pl').
:- ensure_loaded('facts.pl').

% 1. MEDICAL PRIORITY NUMERIC VALUE
decision_medical_score(critical, 10).
decision_medical_score(high, 7).
decision_medical_score(medium, 4).
decision_medical_score(low, 1).

% 2. EVACUATION PRIORITY NUMERIC VALUE
decision_evacuation_score(critical, 10).
decision_evacuation_score(high, 7).
decision_evacuation_score(medium, 4).
decision_evacuation_score(low, 1).

% 3. DECISION PRIORITY SCORE
decision_priority_score(
    RiskScore,
    MedicalPriority,
    EvacuationPriority,
    Score
) :-
    decision_medical_score(
        MedicalPriority,
        MedicalScore
    ),
    decision_evacuation_score(
        EvacuationPriority,
        EvacuationScore
    ),
    Score is
        RiskScore
        + MedicalScore
        + EvacuationScore.

% 4. PRIMARY ACTION
primary_action(
    critical,
    _MedicalPriority,
    _EvacuationPriority,
    immediate_evacuation
) :-
    !.

primary_action(
    _RiskLevel,
    critical,
    _EvacuationPriority,
    immediate_medical_response
) :-
    !.

primary_action(
    _RiskLevel,
    _MedicalPriority,
    critical,
    immediate_evacuation
) :-
    !.

primary_action(
    high,
    _MedicalPriority,
    _EvacuationPriority,
    priority_evacuation
) :-
    !.

primary_action(
    _RiskLevel,
    high,
    _EvacuationPriority,
    priority_medical_response
) :-
    !.

primary_action(
    _RiskLevel,
    _MedicalPriority,
    high,
    priority_evacuation
) :-
    !.

primary_action(
    _RiskLevel,
    medium,
    _EvacuationPriority,
    controlled_response
) :-
    !.

primary_action(
    _RiskLevel,
    _MedicalPriority,
    medium,
    controlled_evacuation
) :-
    !.

primary_action(
    _RiskLevel,
    _MedicalPriority,
    _EvacuationPriority,
    monitoring
).

% 5. ZONE EVALUATION
decision_zone_evaluation(
    Zone,
    RiskLevel,
    RiskScore,
    MedicalPriority,
    EvacuationPriority
) :-
    zone_risk_level(
        Zone,
        RiskLevel
    ),
    zone_risk_score(
        Zone,
        RiskScore
    ),
    medical_priority(
        Zone,
        MedicalPriority
    ),
    evacuation_priority(
        Zone,
        EvacuationPriority
    ).

% 6. AMBULANCE STATUS
zone_ambulance_status(
    Zone,
    Status
) :-
    find_ambulances(
        Zone,
        Ambulances
    ),
    (
        Ambulances = []
        ->
        Status = unavailable
        ;
        Status = available
    ).

% 7. HOSPITAL STATUS
zone_hospital_status(
    Zone,
    Status
) :-
    find_hospitals(
        Zone,
        Hospitals
    ),
    (
        Hospitals = []
        ->
        Status = unavailable
        ;
        Status = available
    ).

% 8. SHELTER STATUS
zone_shelter_status(
    Zone,
    Status
) :-
    find_shelters(
        Zone,
        Shelters
    ),
    (
        Shelters = []
        ->
        Status = unavailable
        ;
        Status = available
    ).

% 9. COMPLETE RESOURCE STATUS
zone_resource_status(
    Zone,
    resources(
        ambulance(AmbulanceStatus),
        hospital(HospitalStatus),
        shelter(ShelterStatus)
    )
) :-
    zone_ambulance_status(
        Zone,
        AmbulanceStatus
    ),
    zone_hospital_status(
        Zone,
        HospitalStatus
    ),
    zone_shelter_status(
        Zone,
        ShelterStatus
    ).

% 10. AMBULANCE ALLOCATION
zone_ambulance_allocation(
    Zone,
    Allocation
) :-
    allocate_ambulance(
        Zone,
        Allocation
    ).

% 11. HOSPITAL ALLOCATION
zone_hospital_allocation(
    Zone,
    Allocation
) :-
    allocate_hospital(
        Zone,
        Allocation
    ).

% 12. SHELTER ALLOCATION
zone_shelter_allocation(
    Zone,
    Allocation
) :-
    allocate_shelter(
        Zone,
        Allocation
    ).

% 13. AMBULANCE INFORMATION
extract_ambulance(
    allocation(
        Ambulance,
        Zone,
        Path,
        Cost,
        Capability,
        Capacity
    ),
    ambulance(
        Ambulance,
        Zone,
        Path,
        Cost,
        Capability,
        Capacity
    )
) :-
    Ambulance \= none,
    !.

extract_ambulance(
    _,
    ambulance(
        none,
        none,
        [],
        0,
        none,
        0
    )
).

% 14. HOSPITAL INFORMATION
extract_hospital(
    hospital_allocation(
        Hospital,
        Zone,
        HospitalZone,
        Path,
        Cost,
        Patients,
        TotalCapacity,
        AvailableCapacity,
        Status,
        Capability
    ),
    hospital(
        Hospital,
        Zone,
        HospitalZone,
        Path,
        Cost,
        Patients,
        TotalCapacity,
        AvailableCapacity,
        Status,
        Capability
    )
) :-
    Hospital \= none,
    !.

extract_hospital(
    _,
    hospital(
        none,
        none,
        none,
        [],
        0,
        0,
        0,
        0,
        unavailable,
        none
    )
).

% 15. SHELTER INFORMATION
extract_shelter(
    shelter_allocation(
        Shelter,
        Zone,
        ShelterZone,
        Path,
        Cost,
        People,
        TotalCapacity,
        AvailableCapacity,
        Status,
        MedicalSupport,
        FamilyFriendly,
        AccessibilitySupport
    ),
    shelter(
        Shelter,
        Zone,
        ShelterZone,
        Path,
        Cost,
        People,
        TotalCapacity,
        AvailableCapacity,
        Status,
        MedicalSupport,
        FamilyFriendly,
        AccessibilitySupport
    )
) :-
    Shelter \= none,
    !.

extract_shelter(
    _,
    shelter(
        none,
        none,
        none,
        [],
        0,
        0,
        0,
        0,
        unavailable,
        none,
        no,
        no
    )
).

% 16. OPERATOR OVERRIDE
effective_decision_action(
    Zone,
    AIAction,
    FinalAction
) :-
    (
        operator_override(
            Zone,
            decision,
            OverrideAction
        )
        ->
        FinalAction = OverrideAction
        ;
        FinalAction = AIAction
    ).

% 17. DECISION REASON
decision_reason(
    RiskLevel,
    RiskScore,
    MedicalPriority,
    EvacuationPriority,
    Action,
    Reason
) :-
    Reason =
        reason(
            risk_level(RiskLevel),
            risk_score(RiskScore),
            medical_priority(MedicalPriority),
            evacuation_priority(EvacuationPriority),
            recommended_action(Action)
        ).

% 18. COMPLETE ZONE DECISION
make_zone_decision(
    Zone,
    Decision
) :-
    decision_zone_evaluation(
        Zone,
        RiskLevel,
        RiskScore,
        MedicalPriority,
        EvacuationPriority
    ),
    decision_priority_score(
        RiskScore,
        MedicalPriority,
        EvacuationPriority,
        PriorityScore
    ),
    primary_action(
        RiskLevel,
        MedicalPriority,
        EvacuationPriority,
        AIAction
    ),
    effective_decision_action(
        Zone,
        AIAction,
        FinalAction
    ),
    zone_resource_status(
        Zone,
        ResourceStatus
    ),
    once(zone_ambulance_allocation(
        Zone,
        AmbulanceAllocation
    )),
    once(zone_hospital_allocation(
        Zone,
        HospitalAllocation
    )),
    once(zone_shelter_allocation(
        Zone,
        ShelterAllocation
    )),
    extract_ambulance(
        AmbulanceAllocation,
        Ambulance
    ),
    extract_hospital(
        HospitalAllocation,
        Hospital
    ),
    extract_shelter(
        ShelterAllocation,
        Shelter
    ),
    decision_reason(
        RiskLevel,
        RiskScore,
        MedicalPriority,
        EvacuationPriority,
        FinalAction,
        Reason
    ),
    Decision =
        decision(
            Zone,
            risk(
                RiskLevel,
                RiskScore
            ),
            medical(
                MedicalPriority
            ),
            evacuation(
                EvacuationPriority
            ),
            priority_score(
                PriorityScore
            ),
            action(
                FinalAction
            ),
            Ambulance,
            Hospital,
            Shelter,
            resources(
                ResourceStatus
            ),
            reason(
                Reason
            )
        ).

% 19. ONE ZONE DECISION
% Decisions are produced once per run by allocate_all_zones/0 and cached, so
% every consumer (plan, explanation, metrics, single-zone view) sees the same
% allocation.
zone_decision(
    Zone,
    Decision
) :-
    ensure_allocation,
    decision_cache(
        Zone,
        Decision
    ).

ensure_allocation :-
    decision_cache(_, _),
    !.

ensure_allocation :-
    allocate_all_zones.

% Allocate zones in descending priority score (ties keep zone/1 order).
% Each decision commits its ambulance, hospital beds and shelter places
% before the next zone is considered.
allocate_all_zones :-
    retractall(decision_cache(_, _)),
    retractall(committed(_, _, _)),
    findall(
        NegativeScore-Zone,
        (
            zone(Zone),
            decision_zone_evaluation(
                Zone,
                _RiskLevel,
                RiskScore,
                MedicalPriority,
                EvacuationPriority
            ),
            decision_priority_score(
                RiskScore,
                MedicalPriority,
                EvacuationPriority,
                Score
            ),
            NegativeScore is -Score
        ),
        Keyed
    ),
    keysort(
        Keyed,
        Ordered
    ),
    forall(
        member(
            _-Zone,
            Ordered
        ),
        ignore(allocate_zone(Zone))
    ).

allocate_zone(Zone) :-
    make_zone_decision(
        Zone,
        Decision
    ),
    assertz(decision_cache(Zone, Decision)),
    commit_decision(Decision).

commit_decision(
    decision(_, _, _, _, _, _, Ambulance, Hospital, Shelter, _, _)
) :-
    commit(ambulance, Ambulance, 1),
    arg(6, Hospital, Patients),
    commit(hospital, Hospital, Patients),
    arg(6, Shelter, People),
    commit(shelter, Shelter, People).

% The first argument of an allocation term is the resource name (or none).
commit(_Kind, Resource, _Amount) :-
    arg(1, Resource, none),
    !.

commit(Kind, Resource, Amount) :-
    arg(1, Resource, Name),
    assertz(committed(Kind, Name, Amount)).

% 20. ALL ZONE DECISIONS
all_zone_decisions(
    Decisions
) :-
    findall(
        Decision,
        (
            zone(Zone),
            once(zone_decision(
                Zone,
                Decision
            ))
        ),
        Decisions
    ).

% 21. HIGH PRIORITY DECISIONS
high_priority_decision(
    decision(
        _Zone,
        _Risk,
        _Medical,
        _Evacuation,
        priority_score(Score),
        _Action,
        _Ambulance,
        _Hospital,
        _Shelter,
        _Resources,
        _Reason
    )
) :-
    Score >= 30.

% 22. FIND HIGH PRIORITY ZONES
find_high_priority_decisions(
    Decisions
) :-
    findall(
        Decision,
        (
            zone_decision(
                _Zone,
                Decision
            ),
            high_priority_decision(
                Decision
            )
        ),
        Decisions
    ).

% 23. DECISION SUMMARY
decision_summary(
    Summary
) :-
    all_zone_decisions(
        Decisions
    ),
    length(
        Decisions,
        TotalZones
    ),
    findall(
        Zone,
        (
            member(
                decision(
                    Zone,
                    risk(critical, _),
                    _,
                    _,
                    _,
                    _,
                    _,
                    _,
                    _,
                    _,
                    _
                ),
                Decisions
            )
        ),
        CriticalZones
    ),
    findall(
        Zone,
        (
            member(
                decision(
                    Zone,
                    _,
                    medical(critical),
                    _,
                    _,
                    _,
                    _,
                    _,
                    _,
                    _,
                    _
                ),
                Decisions
            )
        ),
        MedicalEmergencyZones
    ),
    Summary =
        decision_summary(
            total_zones(TotalZones),
            critical_zones(CriticalZones),
            medical_emergency_zones(MedicalEmergencyZones),
            decisions(Decisions)
        ).

% 24. SYSTEM DECISION
system_decision(
    Decision
) :-
    decision_summary(
        Summary
    ),
    Decision =
        system_decision(
            Summary
        ).