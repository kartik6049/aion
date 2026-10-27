:- ensure_loaded('rules.pl').
:- ensure_loaded('search.pl').
:- ensure_loaded('astar.pl').
:- ensure_loaded('facts.pl').

% 1. AMBULANCE AVAILABILITY
available_ambulance(Ambulance) :-
    ambulance_state(
        Ambulance,
        _Location,
        available,
        _Capability,
        _Capacity
    ).

% 2. AMBULANCE INFORMATION
ambulance_information(
    Ambulance,
    Information
) :-
    ambulance_state(
        Ambulance,
        Location,
        Status,
        Capability,
        Capacity
    ),
    Information =
        ambulance_info(
            Ambulance,
            Location,
            Status,
            Capability,
            Capacity
        ).

% 3. AMBULANCE CAN HANDLE MEDICAL PRIORITY
ambulance_capability_score(
    basic,
    1
).

ambulance_capability_score(
    advanced,
    2
).

ambulance_capability_score(
    critical_care,
    3
).

ambulance_capability_score(
    trauma,
    3
).

required_ambulance_capability(
    Zone,
    critical_care
) :-
    medical_priority(
        Zone,
        critical
    ).

required_ambulance_capability(
    Zone,
    advanced
) :-
    medical_priority(
        Zone,
        high
    ).

required_ambulance_capability(
    Zone,
    basic
) :-
    medical_priority(
        Zone,
        medium
    ).

required_ambulance_capability(
    Zone,
    basic
) :-
    medical_priority(
        Zone,
        low
    ).

ambulance_can_handle(
    Ambulance,
    Zone
) :-
    ambulance_state(
        Ambulance,
        _Location,
        available,
        Capability,
        _Capacity
    ),
    required_ambulance_capability(
        Zone,
        Required
    ),
    ambulance_capability_score(
        Capability,
        ActualScore
    ),
    ambulance_capability_score(
        Required,
        RequiredScore
    ),
    ActualScore >= RequiredScore.

% 4. AMBULANCE CAN TRANSPORT EVACUATION GROUP
ambulance_can_transport(
    Ambulance,
    Zone
) :-
    ambulance_state(
        Ambulance,
        _,_,_,
        Capacity
    ),
    medical_cases(
        Zone,
        Critical,
        Serious,
        Minor
    ),
    TotalPatients is Critical + Serious + Minor,
    TotalPatients > 0,
    Capacity > 0.

% 5. AMBULANCE ROUTE
ambulance_can_reach(
    Ambulance,
    Zone,
    Path
) :-
    ambulance_state(
        Ambulance,
        Start,
        available,
        _Capability,
        _Capacity
    ),
    astar(
        Start,
        Zone,
        Path,
        _Cost
    ).

% 6. COMPLETE AMBULANCE ELIGIBILITY
eligible_ambulance(
    Ambulance,
    Zone,
    Path,
    Cost
) :-
    available_ambulance(
        Ambulance
    ),
    \+ committed(ambulance, Ambulance, _),
    ambulance_can_handle(
        Ambulance,
        Zone
    ),
    ambulance_can_transport(
        Ambulance,
        Zone
    ),
    ambulance_can_reach(
        Ambulance,
        Zone,
        Path
    ),
    route_cost(
        Path,
        Cost
    ).

% 7. EVALUATE AMBULANCE
evaluate_ambulance(
    Ambulance,
    Zone,
    Evaluation
) :-
    eligible_ambulance(
        Ambulance,
        Zone,
        Path,
        Cost
    ),
    ambulance_state(
        Ambulance,
        _Location,
        _Status,
        Capability,
        Capacity
    ),
    Evaluation =
        ambulance_evaluation(
            Ambulance,
            Zone,
            Path,
            Cost,
            Capability,
            Capacity
        ).

% 8. FIND ALL ELIGIBLE AMBULANCES
find_ambulances(
    Zone,
    Ambulances
) :-
    findall(
        Ambulance,
        eligible_ambulance(
            Ambulance,
            Zone,
            _Path,
            _Cost
        ),
        AllAmbulances
    ),
    sort(
        AllAmbulances,Ambulances).

% Route risk penalty
route_risk_penalty(low,0).
route_risk_penalty(medium,5).
route_risk_penalty(high,15).
route_risk_penalty(critical,30).
route_risk_penalty(unknown,10).

% 9. AMBULANCE PRIORITY SCORE
ambulance_selection_score(
    Zone,
    Ambulance,
    Path,
    Cost,
    Score
) :-
    ambulance_state(
        Ambulance,
        _Location,
        _Status,
        Capability,
        Capacity
    ),
    ambulance_capability_score(
        Capability,
        CapabilityScore
    ),
    evacuation_population(
        Zone,
        People
    ),
    route_risk(
        Path,
        Risk
    ),
    route_risk_penalty(
        Risk,
        RiskPenalty
    ),
    Score is
        Cost
        + RiskPenalty
        - CapabilityScore
        + max(0, People - Capacity).

% 10. SORT AMBULANCES
sort_ambulances(
    Evaluations,
    Sorted
) :-
    make_ambulance_keys(
        Evaluations,
        Keyed
    ),
    keysort(
        Keyed,
        SortedKeyed
    ),
    remove_ambulance_keys(
        SortedKeyed,
        Sorted
    ).

make_ambulance_keys(
    [],
    []
).

make_ambulance_keys(
    [
        ambulance_evaluation(
            A,
            Z,
            Path,
            Cost,
            Capability,
            Capacity
        )
        | Rest
    ],
    [
        Score-
        ambulance_evaluation(
            A,
            Z,
            Path,
            Cost,
            Capability,
            Capacity
        )
        | KeyedRest
    ]
) :-
    ambulance_selection_score(
        Z,
        A,
        Path,
        Cost,
        Score
    ),
    make_ambulance_keys(
        Rest,
        KeyedRest
    ).

remove_ambulance_keys(
    [],
    []
).

remove_ambulance_keys(
    [
        _Score-Evaluation
        | Rest
    ],
    [
        Evaluation
        | Evaluations
    ]
) :-
    remove_ambulance_keys(
        Rest,
        Evaluations
    ).

% 11. BEST AMBULANCE
best_ambulance(
    Zone,
    BestEvaluation
) :-
    findall(
        Evaluation,
        evaluate_ambulance(
            _Ambulance,
            Zone,
            Evaluation
        ),
        Evaluations
    ),
    Evaluations \= [],
    sort_ambulances(
        Evaluations,
        [
            BestEvaluation
            | _
        ]
    ).

% 12. ALLOCATE ONE AMBULANCE
allocate_ambulance(
    Zone,
    Allocation
) :-
    best_ambulance(
        Zone,
        ambulance_evaluation(
            Ambulance,
            Zone,
            Path,
            Cost,
            Capability,
            Capacity
        )
    ),
    Allocation =
        allocation(
            Ambulance,
            Zone,
            Path,
            Cost,
            Capability,
            Capacity
        ).

% 13. NO AMBULANCE AVAILABLE
allocate_ambulance(
    Zone,
    allocation(
        none,
        Zone,
        [],
        0,
        none,
        0
    )
) :-
    \+
    best_ambulance(
        Zone,
        _
    ).

% 14. RESOURCE-AWARE AMBULANCE ALLOCATION
allocate_ambulances(
    [],
    _AvailableAmbulances,
    []
).

allocate_ambulances(
    [
        evaluation(
            Zone,
            _RiskLevel,
            _RiskScore,
            _MedicalPriority,
            Priority
        )
        | Rest
    ],
    AvailableAmbulances,
    [
        Allocation
        | RestAllocations
    ]
) :-
    allocate_best_ambulance(
        Zone,
        Priority,
        AvailableAmbulances,
        Allocation,
        RemainingAmbulances
    ),
    allocate_ambulances(
        Rest,
        RemainingAmbulances,
        RestAllocations
    ).

% 15. ALLOCATE BEST AVAILABLE AMBULANCE
allocate_best_ambulance(
    Zone,
    Priority,
    AvailableAmbulances,
    allocation(
        Ambulance,
        Zone,
        Priority,
        Path,
        Cost,
        Capability,
        Capacity
    ),
    RemainingAmbulances
) :-
    findall(
        ambulance_evaluation(
            A,
            Zone,
            Route,
            RouteCost,
            ACapability,
            ACapacity
        ),
        (
            member(
                A,
                AvailableAmbulances
            ),
            evaluate_ambulance(
                A,
                Zone,
                ambulance_evaluation(
                    A,
                    Zone,
                    Route,
                    RouteCost,
                    ACapability,
                    ACapacity
                )
            )
        ),
        Evaluations
    ),
    Evaluations \= [],
    sort_ambulances(
        Evaluations,
        [
            ambulance_evaluation(
                Ambulance,
                Zone,
                Path,
                Cost,
                Capability,
                Capacity
            )
            | _
        ]
    ),
    select(
        Ambulance,
        AvailableAmbulances,
        RemainingAmbulances
    ).

% 16. NO AMBULANCE IN RESOURCE POOL
allocate_best_ambulance(
    Zone,
    Priority,
    [],
    allocation(
        none,
        Zone,
        Priority,
        [],
        0,
        none,
        0
    ),
    []
).

% HOSPITAL RESOURCE MANAGEMENT
% 17. HOSPITAL AVAILABILITY
available_hospital(
    Hospital
) :-
    hospital_state(
        Hospital,
        _Zone,
        _TotalCapacity,
        AvailableCapacity,
        Status,
        _Capability
    ),
    AvailableCapacity > 0,
    (
        Status = operational
    ;
        Status = limited
    ).

% 18. HOSPITAL INFORMATION
hospital_information(
    Hospital,
    Information
) :-
    hospital_state(
        Hospital,
        Zone,
        TotalCapacity,
        AvailableCapacity,
        Status,
        Capability
    ),
    Information =
        hospital_info(
            Hospital,
            Zone,
            TotalCapacity,
            AvailableCapacity,
            Status,
            Capability
        ).

% 19. HOSPITAL CAPABILITY SCORE
hospital_capability_score(
    basic,
    1
).

hospital_capability_score(
    advanced,
    2
).

hospital_capability_score(
    trauma,
    3
).

% 20. REQUIRED HOSPITAL CAPABILITY
required_hospital_capability(
    Zone,
    trauma
) :-
    medical_priority(
        Zone,
        critical
    ).

required_hospital_capability(
    Zone,
    advanced
) :-
    medical_priority(
        Zone,
        high
    ).

required_hospital_capability(
    Zone,
    basic
) :-
    medical_priority(
        Zone,
        medium
    ).

required_hospital_capability(
    Zone,
    basic
) :-
    medical_priority(
        Zone,
        low
    ).

% 21. HOSPITAL CAN HANDLE ZONE
hospital_can_handle(
    Hospital,
    Zone
) :-
    hospital_state(
        Hospital,
        _HospitalZone,
        _TotalCapacity,
        AvailableCapacity,
        Status,
        Capability
    ),
    AvailableCapacity > 0,
    (
        Status = operational
    ;
        Status = limited
    ),
    required_hospital_capability(
        Zone,
        RequiredCapability
    ),
    hospital_capability_score(
        Capability,
        ActualScore
    ),
    hospital_capability_score(
        RequiredCapability,
        RequiredScore
    ),
    ActualScore >= RequiredScore.

% 22. HOSPITAL HAS ENOUGH CAPACITY
hospital_can_accept_patients(
    Hospital,
    Zone
) :-
    hospital_state(
        Hospital,
        _HospitalZone,
        _TotalCapacity,
        AvailableCapacity,
        _Status,
        _Capability
    ),
    medical_case_total(
        Zone,
        MedicalCases
    ),
    committed_amount(hospital, Hospital, Used),
    AvailableCapacity - Used >= MedicalCases.

% 23. HOSPITAL ROUTE
hospital_can_reach(
    Hospital,
    Zone,
    Path
) :-
    hospital_state(
        Hospital,
        HospitalZone,
        _TotalCapacity,
        AvailableCapacity,
        Status,
        _Capability
    ),
    AvailableCapacity > 0,
    (
        Status = operational
    ;
        Status = limited
    ),
    astar(
        Zone,
        HospitalZone,
        Path,
        _Cost
    ).

% 24. EVALUATE HOSPITAL
evaluate_hospital(
    Hospital,
    Zone,
    Evaluation
) :-
    hospital_can_handle(
        Hospital,
        Zone
    ),
    hospital_can_accept_patients(
        Hospital,
        Zone
    ),
    hospital_can_reach(
        Hospital,
        Zone,
        Path
    ),
    route_cost(
        Path,
        Cost
    ),
    hospital_state(
        Hospital,
        HospitalZone,
        TotalCapacity,
        StateCapacity,
        Status,
        Capability
    ),
    committed_amount(hospital, Hospital, Used),
    AvailableCapacity is StateCapacity - Used,
    Evaluation =
        hospital_evaluation(
            Hospital,
            Zone,
            HospitalZone,
            Path,
            Cost,
            TotalCapacity,
            AvailableCapacity,
            Status,
            Capability
        ).

% 25. FIND HOSPITALS
find_hospitals(
    Zone,
    Hospitals
) :-
    findall(
        Hospital,
        evaluate_hospital(
            Hospital,
            Zone,
            _Evaluation
        ),
        Hospitals
    ).

% 26. HOSPITAL SELECTION SCORE
hospital_selection_score(
    _Zone,
    _Hospital,
    Path,
    Cost,
    TotalCapacity,
    AvailableCapacity,
    Capability,
    Score
) :-
    hospital_capability_score(
        Capability,
        CapabilityScore
    ),
    route_risk(
        Path,
        Risk
    ),
    road_risk_penalty(
        Risk,
        RiskPenalty
    ),
    CapacityPercentage is
        (AvailableCapacity * 100)
        / TotalCapacity,
    CapacityPenalty is
        max(
            0,
            50 - CapacityPercentage
        ),
    Score is
        Cost
        + RiskPenalty
        + CapacityPenalty
        - CapabilityScore.

% 27. SORT HOSPITALS
sort_hospitals(
    Evaluations,
    Sorted
) :-
    make_hospital_keys(
        Evaluations,
        Keyed
    ),
    keysort(
        Keyed,
        SortedKeyed
    ),
    remove_hospital_keys(
        SortedKeyed,
        Sorted
    ).

make_hospital_keys(
    [],
    []
).

make_hospital_keys(
    [
        hospital_evaluation(
            Hospital,
            Zone,
            HospitalZone,
            Path,
            Cost,
            TotalCapacity,
            AvailableCapacity,
            Status,
            Capability
        )
        | Rest
    ],
    [
        Score-
        hospital_evaluation(
            Hospital,
            Zone,
            HospitalZone,
            Path,
            Cost,
            TotalCapacity,
            AvailableCapacity,
            Status,
            Capability
        )
        | KeyedRest
    ]
) :-
    hospital_selection_score(
        Zone,
        Hospital,
        Path,
        Cost,
        TotalCapacity,
        AvailableCapacity,
        Capability,
        Score
    ),
    make_hospital_keys(
        Rest,
        KeyedRest
    ).

remove_hospital_keys(
    [],
    []
).

remove_hospital_keys(
    [
        _Score-Evaluation
        | Rest
    ],
    [
        Evaluation
        | Evaluations
    ]
) :-
    remove_hospital_keys(
        Rest,
        Evaluations
    ).

% 28. BEST HOSPITAL
best_hospital(
    Zone,
    BestEvaluation
) :-
    findall(
        Evaluation,
        evaluate_hospital(
            _Hospital,
            Zone,
            Evaluation
        ),
        Evaluations
    ),
    Evaluations \= [],
    sort_hospitals(
        Evaluations,
        [
            BestEvaluation
            | _
        ]
    ).

% 29. ALLOCATE HOSPITAL
allocate_hospital(
    Zone,
    Allocation
) :-
    best_hospital(
        Zone,
        hospital_evaluation(
            Hospital,
            Zone,
            HospitalZone,
            Path,
            Cost,
            TotalCapacity,
            AvailableCapacity,
            Status,
            Capability
        )
    ),
    medical_case_total(
        Zone,
        Patients
    ),
    Allocation =
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
        ).

% 30. NO HOSPITAL AVAILABLE
allocate_hospital(
    Zone,
    hospital_allocation(
        none,
        Zone,
        none,
        [],
        0,
        0,
        0,
        0,
        unavailable,
        none
    )
) :-
    \+
    best_hospital(
        Zone,
        _
    ).

% SHELTER RESOURCE MANAGEMENT
% 31. SHELTER AVAILABILITY
available_shelter(
    Shelter
) :-
    shelter_state(
        Shelter,
        _Zone,
        _TotalCapacity,
        AvailableCapacity,
        Status
    ),
    AvailableCapacity > 0,
    (
        Status = operational
    ;
        Status = limited
    ).

% 32. SHELTER INFORMATION
shelter_information(
    Shelter,
    Information
) :-
    shelter_state(
        Shelter,
        Zone,
        TotalCapacity,
        AvailableCapacity,
        Status
    ),
    Information =
        shelter_info(
            Shelter,
            Zone,
            TotalCapacity,
            AvailableCapacity,
            Status
        ).

% 33. SHELTER CAN ACCOMMODATE
shelter_can_accommodate(
    Shelter,
    Zone
) :-
    shelter_state(
        Shelter,
        _ShelterZone,
        _TotalCapacity,
        AvailableCapacity,
        Status
    ),
    AvailableCapacity > 0,
    (
        Status = operational
    ;
        Status = limited
    ),
    evacuation_population(
        Zone,
        People
    ),
    committed_amount(shelter, Shelter, Used),
    AvailableCapacity - Used >= People.

% 34. SHELTER ACCESSIBILITY
shelter_can_reach(
    Shelter,
    Zone,
    Path
) :-
    shelter_state(
        Shelter,
        ShelterZone,
        _TotalCapacity,
        _AvailableCapacity,
        _Status
    ),
    astar(
        Zone,
        ShelterZone,
        Path,
        _Cost
    ).

% 35. SHELTER MEDICAL SUPPORT
shelter_medical_score(
    no,
    0
).

shelter_medical_score(
    basic,
    1
).

shelter_medical_score(
    yes,
    2
).

shelter_medical_score(
    advanced,
    3
).

% 36. EVALUATE SHELTER
evaluate_shelter(
    Shelter,
    Zone,
    Evaluation
) :-
    shelter_can_accommodate(
        Shelter,
        Zone
    ),
    shelter_can_reach(
        Shelter,
        Zone,
        Path
    ),
    route_cost(
        Path,
        Cost
    ),
    shelter_state(
        Shelter,
        ShelterZone,
        TotalCapacity,
        StateCapacity,
        Status
    ),
    committed_amount(shelter, Shelter, Used),
    AvailableCapacity is StateCapacity - Used,
    shelter_features(
        Shelter,
        MedicalSupport,
        FamilyFriendly,
        AccessibilitySupport
    ),
    shelter_medical_score(
        MedicalSupport,
        MedicalScore
    ),
    Evaluation =
        shelter_evaluation(
            Shelter,
            Zone,
            ShelterZone,
            Path,
            Cost,
            TotalCapacity,
            AvailableCapacity,
            Status,
            MedicalSupport,
            FamilyFriendly,
            AccessibilitySupport,
            MedicalScore
        ).

% 37. FIND SHELTERS
find_shelters(
    Zone,
    Shelters
) :-
    findall(
        Shelter,
        evaluate_shelter(
            Shelter,
            Zone,
            _Evaluation
        ),
        Shelters
    ).

% 38. SHELTER SELECTION SCORE
shelter_selection_score(
    _Zone,
    _Shelter,
    Path,
    Cost,
    TotalCapacity,
    AvailableCapacity,
    MedicalScore,
    Score
) :-
    route_risk(
        Path,
        Risk
    ),
    road_risk_penalty(
        Risk,
        RiskPenalty
    ),
    CapacityPercentage is
        (AvailableCapacity * 100)
        / TotalCapacity,
    CapacityBonus is
        CapacityPercentage / 20,
    Score is
        Cost
        + RiskPenalty
        - CapacityBonus
        - MedicalScore.

% 39. SORT SHELTERS
sort_shelters(
    Evaluations,
    Sorted
) :-
    make_shelter_keys(
        Evaluations,
        Keyed
    ),
    keysort(
        Keyed,
        SortedKeyed
    ),
    remove_shelter_keys(
        SortedKeyed,
        Sorted
    ).

make_shelter_keys(
    [],
    []
).

make_shelter_keys(
    [
        shelter_evaluation(
            Shelter,
            Zone,
            ShelterZone,
            Path,
            Cost,
            TotalCapacity,
            AvailableCapacity,
            Status,
            MedicalSupport,
            FamilyFriendly,
            AccessibilitySupport,
            MedicalScore
        )
        | Rest
    ],
    [
        Score-
        shelter_evaluation(
            Shelter,
            Zone,
            ShelterZone,
            Path,
            Cost,
            TotalCapacity,
            AvailableCapacity,
            Status,
            MedicalSupport,
            FamilyFriendly,
            AccessibilitySupport,
            MedicalScore
        )
        | KeyedRest
    ]
) :-
    shelter_selection_score(
        Zone,
        Shelter,
        Path,
        Cost,
        TotalCapacity,
        AvailableCapacity,
        MedicalScore,
        Score
    ),
    make_shelter_keys(
        Rest,
        KeyedRest
    ).

remove_shelter_keys(
    [],
    []
).

remove_shelter_keys(
    [
        _Score-Evaluation
        | Rest
    ],
    [
        Evaluation
        | Evaluations
    ]
) :-
    remove_shelter_keys(
        Rest,
        Evaluations
    ).

% 40. BEST SHELTER
best_shelter(
    Zone,
    BestEvaluation
) :-
    findall(
        Evaluation,
        evaluate_shelter(
            _Shelter,
            Zone,
            Evaluation
        ),
        Evaluations
    ),
    Evaluations \= [],
    sort_shelters(
        Evaluations,
        [
            BestEvaluation
            | _
        ]
    ).

% 41. ALLOCATE SHELTER
allocate_shelter(
    Zone,
    Allocation
) :-
    best_shelter(
        Zone,
        shelter_evaluation(
            Shelter,
            Zone,
            ShelterZone,
            Path,
            Cost,
            TotalCapacity,
            AvailableCapacity,
            Status,
            MedicalSupport,
            FamilyFriendly,
            AccessibilitySupport,
            _MedicalScore
        )
    ),
    evacuation_population(
        Zone,
        People
    ),
    Allocation =
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
        ).

% 42. NO SHELTER AVAILABLE
allocate_shelter(
    Zone,
    shelter_allocation(
        none,
        Zone,
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
) :-
    \+
    best_shelter(
        Zone,
        _
    ).

% STATE-AWARE SHELTER ALLOCATION
% 43. INITIAL SHELTER STATE
initial_shelter_state(
    State
) :-
    findall(
        shelter_state(
            Shelter,
            AvailableCapacity
        ),
        (
            shelter_state(
                Shelter,
                _Zone,
                _TotalCapacity,
                AvailableCapacity,
                Status
            ),
            (
                Status = operational
            ;
                Status = limited
            )
        ),
        State
    ).

% 44. SUITABLE SHELTER USING PLANNING STATE
suitable_shelter_state(
    Shelter,
    Zone,
    ShelterState
) :-
    evacuation_population(
        Zone,
        People
    ),
    member(
        shelter_state(
            Shelter,
            AvailableCapacity
        ),
        ShelterState
    ),
    AvailableCapacity >= People,
    shelter_state(
        Shelter,
        ShelterZone,
        _TotalCapacity,
        _CurrentAvailable,
        Status
    ),
    (
        Status = operational
    ;
        Status = limited
    ),
    astar(
        Zone,
        ShelterZone,
        _Path,
        _Cost
    ).

% 45. UPDATE SHELTER STATE
update_shelter_state(
    [],
    _Shelter,
    _NewCapacity,
    []
).

update_shelter_state(
    [
        shelter_state(
            Shelter,
            _
        )
        | Rest
    ],
    Shelter,
    NewCapacity,
    [
        shelter_state(
            Shelter,
            NewCapacity
        )
        | Rest
    ]
) :-
    !.

update_shelter_state(
    [
        State
        | Rest
    ],
    Shelter,
    NewCapacity,
    [
        State
        | UpdatedRest
    ]
) :-
    update_shelter_state(
        Rest,
        Shelter,
        NewCapacity,
        UpdatedRest
    ).

% 46. RESOURCE-AWARE SHELTER ALLOCATION
allocate_shelters(
    [],
    _ShelterState,
    []
).

allocate_shelters(
    [
        evaluation(
            Zone,
            _RiskLevel,
            _RiskScore,
            _MedicalPriority,
            Priority
        )
        | Rest
    ],
    ShelterState,
    [
        Allocation
        | RestAllocations
    ]
) :-
    allocate_best_shelter(
        Zone,
        Priority,
        ShelterState,
        Allocation,
        UpdatedShelterState
    ),
    allocate_shelters(
        Rest,
        UpdatedShelterState,
        RestAllocations
    ).

% 47. ALLOCATE BEST SHELTER
allocate_best_shelter(
    Zone,
    Priority,
    ShelterState,
    allocation(
        Shelter,
        Zone,
        Priority,
        People,
        RemainingCapacity,
        Path,
        Cost
    ),
    UpdatedState
) :-
    evacuation_population(
        Zone,
        People
    ),
    findall(
        Cost-Shelter-Path-Available,
        (
            member(
                shelter_state(
                    Shelter,
                    Available
                ),
                ShelterState
            ),
            Available >= People,
            shelter_state(
                Shelter,
                ShelterZone,
                _TotalCapacity,
                _ActualCapacity,
                Status
            ),
            (
                Status = operational
            ;
                Status = limited
            ),
            astar(
                Zone,
                ShelterZone,
                Path,
                Cost
            )
        ),
        Candidates
    ),
    Candidates \= [],
    keysort(
        Candidates,
        [
            Cost-Shelter-Path-Available
            | _
        ]
    ),
    RemainingCapacity is
        Available - People,
    update_shelter_state(
        ShelterState,
        Shelter,
        RemainingCapacity,
        UpdatedState
    ).

% 48. NO SUITABLE SHELTER
allocate_best_shelter(
    Zone,
    Priority,
    ShelterState,
    allocation(
        none,
        Zone,
        Priority,
        0,
        0,
        [],
        0
    ),
    ShelterState
) :-
    \+
    (
        suitable_shelter_state(
            _Shelter,
            Zone,
            ShelterState
        )
    ).

% 49. RESOURCE SUMMARY
resource_summary(
    Summary
) :-
    findall(
        ambulance_info(
            Ambulance,
            Location,
            Status,
            Capability,
            Capacity
        ),
        ambulance_state(
            Ambulance,
            Location,
            Status,
            Capability,
            Capacity
        ),
        Ambulances
    ),
    findall(
        hospital_info(
            Hospital,
            HospitalZone,
            TotalCapacity,
            AvailableCapacity,
            HospitalStatus,
            HospitalCapability
        ),
        hospital_state(
            Hospital,
            HospitalZone,
            TotalCapacity,
            AvailableCapacity,
            HospitalStatus,
            HospitalCapability
        ),
        Hospitals
    ),
    findall(
        shelter_info(
            Shelter,
            ShelterZone,
            ShelterTotalCapacity,
            ShelterAvailableCapacity,
            ShelterStatus
        ),
        shelter_state(
            Shelter,
            ShelterZone,
            ShelterTotalCapacity,
            ShelterAvailableCapacity,
            ShelterStatus
        ),
        Shelters
    ),
    Summary =
        resources(
            ambulances(Ambulances),
            hospitals(Hospitals),
            shelters(Shelters)
        ).

% 50. COMMITTED RESOURCES
% Zones are allocated in priority order (see decision_engine.pl). Whatever a
% zone receives is recorded here so that later zones cannot be given it again.
committed_amount(
    Kind,
    Resource,
    Total
) :-
    findall(
        Amount,
        committed(
            Kind,
            Resource,
            Amount
        ),
        Amounts
    ),
    sum_list(
        Amounts,
        Total
    ).

% 51. RESOURCE SHORTAGE REPORT
% A shortage is a zone for which no resource of that kind could be assigned.
resource_shortages(
    Shortages
) :-
    findall(
        shortage(
            Type,
            Zone
        ),
        (
            zone(Zone),
            zone_decision(
                Zone,
                Decision
            ),
            decision_shortage(
                Type,
                Zone,
                Decision
            )
        ),
        Shortages
    ).

decision_shortage(
    hospital,
    Zone,
    decision(_, _, _, _, _, _, _, Hospital, _, _, _)
) :-
    medical_case_total(
        Zone,
        Cases
    ),
    Cases > 0,
    arg(1, Hospital, none).

decision_shortage(
    shelter,
    _Zone,
    decision(_, _, _, _, _, _, _, _, Shelter, _, _)
) :-
    arg(1, Shelter, none).

decision_shortage(
    ambulance,
    _Zone,
    decision(_, _, _, _, _, _, Ambulance, _, _, _, _)
) :-
    arg(1, Ambulance, none).
