:- ensure_loaded('facts.pl').
:- ensure_loaded('rules.pl').
:- ensure_loaded('search.pl').
:- ensure_loaded('astar.pl').
:- ensure_loaded('resource_engine.pl').
:- ensure_loaded('decision_engine.pl').

% 1. BASIC ZONE FACTS
zone_facts(
    Zone,
    Facts
) :-
    population(
        Zone,
        Population
    ),
    evacuation_population(
        Zone,
        EvacuationPopulation
    ),
    vulnerable_population(
        Zone,
        Children,
        Elderly,
        Disabled
    ),
    medical_cases(
        Zone,
        CriticalCases,
        SeriousCases,
        MinorCases
    ),
    zone_condition(
        Zone,
        RiskLevel,
        FloodLevel,
        StructuralDamage,
        PopulationAtRisk,
        Urgency
    ),
    Facts =
        facts(
            population(Population),
            evacuation_population(EvacuationPopulation),
            vulnerable_population(
                children(Children),
                elderly(Elderly),
                disabled(Disabled)
            ),
            medical_cases(
                critical(CriticalCases),
                serious(SeriousCases),
                minor(MinorCases)
            ),
            zone_condition(
                risk_level(RiskLevel),
                flood_level(FloodLevel),
                structural_damage(StructuralDamage),
                population_at_risk(PopulationAtRisk),
                urgency(Urgency)
            )
        ).

% 2. VULNERABLE POPULATION EXPLANATION
vulnerable_explanation(
    Zone,
    Explanation
) :-
    vulnerable_population(
        Zone,
        Children,
        Elderly,
        Disabled
    ),
    Total is
        Children
        + Elderly
        + Disabled,
    Explanation =
        vulnerable_population_summary(
            total(Total),
            children(Children),
            elderly(Elderly),
            disabled(Disabled)
        ).

% 3. MEDICAL EXPLANATION
medical_explanation(
    Zone,
    Explanation
) :-
    medical_cases(
        Zone,
        Critical,
        Serious,
        Minor
    ),
    Total is
        Critical
        + Serious
        + Minor,
    medical_priority(
        Zone,
        Priority
    ),
    Explanation =
        medical_assessment(
            total_cases(Total),
            critical_cases(Critical),
            serious_cases(Serious),
            minor_cases(Minor),
            priority(Priority)
        ).

% 4. RISK EXPLANATION
risk_explanation(
    Zone,
    Explanation
) :-
    zone_risk_score(
        Zone,
        RiskScore
    ),
    zone_risk_level(
        Zone,
        RiskLevel
    ),
    Explanation =
        risk_assessment(
            level(RiskLevel),
            score(RiskScore)
        ).

% 5. EVACUATION EXPLANATION
evacuation_explanation(
    Zone,
    Explanation
) :-
    evacuation_priority(
        Zone,
        Priority
    ),
    evacuation_population(
        Zone,
        People
    ),
    Explanation =
        evacuation_assessment(
            priority(Priority),
            people(People)
        ).

% 6. HOSPITAL CAPACITY EXPLANATION
hospital_capacity_explanation(
    Hospital,
    Explanation
) :-
    hospital_state(
        Hospital,
        Zone,
        TotalCapacity,
        AvailableCapacity,
        Status,
        Capability
    ),
    UsedCapacity is
        TotalCapacity
        - AvailableCapacity,
    Explanation =
        hospital_capacity(
            hospital(Hospital),
            zone(Zone),
            total_capacity(TotalCapacity),
            available_capacity(AvailableCapacity),
            used_capacity(UsedCapacity),
            status(Status),
            capability(Capability)
        ).

% 7. SHELTER CAPACITY EXPLANATION
shelter_capacity_explanation(
    Shelter,
    Explanation
) :-
    shelter_state(
        Shelter,
        Zone,
        TotalCapacity,
        AvailableCapacity,
        Status
    ),
    UsedCapacity is
        TotalCapacity
        - AvailableCapacity,
    Explanation =
        shelter_capacity(
            shelter(Shelter),
            zone(Zone),
            total_capacity(TotalCapacity),
            available_capacity(AvailableCapacity),
            used_capacity(UsedCapacity),
            status(Status)
        ).

% 8. AMBULANCE EXPLANATION
ambulance_explanation(
    Ambulance,
    Explanation
) :-
    ambulance_information(
        Ambulance,
        ambulance_info(
            Ambulance,
            Location,
            Status,
            Capability,
            Capacity
        )
    ),
    Explanation =
        ambulance_resource(
            ambulance(Ambulance),
            location(Location),
            status(Status),
            capability(Capability),
            transport_capacity(Capacity)
        ).

% 9. ROUTE EXPLANATION
route_explanation(
    Path,
    Explanation
) :-
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
    Explanation =
        route_assessment(
            path(Path),
            cost(Cost),
            distance(Distance),
            risk(Risk),
            status(Status)
        ).

% 10. AMBULANCE ROUTE EXPLANATION
ambulance_route_explanation(
    allocation(
        Ambulance,
        Zone,
        Path,
        Cost,
        Capability,
        Capacity
    ),
    Explanation
) :-
    Ambulance \= none,
    route_explanation(
        Path,
        RouteExplanation
    ),
    Explanation =
        ambulance_route(
            ambulance(Ambulance),
            zone(Zone),
            capability(Capability),
            capacity(Capacity),
            cost(Cost),
            route(RouteExplanation)
        ).

ambulance_route_explanation(
    _,
    ambulance_route(
        ambulance(none),
        zone(none),
        capability(none),
        capacity(0),
        cost(0),
        route(unavailable)
    )
).

% 11. HOSPITAL ROUTE EXPLANATION
hospital_route_explanation(
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
    Explanation
) :-
    Hospital \= none,
    route_explanation(
        Path,
        RouteExplanation
    ),
    Explanation =
        hospital_route(
            hospital(Hospital),
            source_zone(Zone),
            destination_zone(HospitalZone),
            patients(Patients),
            capability(Capability),
            total_capacity(TotalCapacity),
            available_capacity(AvailableCapacity),
            status(Status),
            cost(Cost),
            route(RouteExplanation)
        ).

hospital_route_explanation(
    _,
    hospital_route(
        hospital(none),
        source_zone(none),
        destination_zone(none),
        patients(0),
        capability(none),
        total_capacity(0),
        available_capacity(0),
        status(unavailable),
        cost(0),
        route(unavailable)
    )
).

% 12. SHELTER ROUTE EXPLANATION
shelter_route_explanation(
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
    Explanation
) :-
    Shelter \= none,
    route_explanation(
        Path,
        RouteExplanation
    ),
    Explanation =
        shelter_route(
            shelter(Shelter),
            source_zone(Zone),
            destination_zone(ShelterZone),
            people(People),
            total_capacity(TotalCapacity),
            available_capacity(AvailableCapacity),
            status(Status),
            medical_support(MedicalSupport),
            family_friendly(FamilyFriendly),
            accessibility_support(AccessibilitySupport),
            cost(Cost),
            route(RouteExplanation)
        ).

shelter_route_explanation(
    _,
    shelter_route(
        shelter(none),
        source_zone(none),
        destination_zone(none),
        people(0),
        total_capacity(0),
        available_capacity(0),
        status(unavailable),
        medical_support(none),
        family_friendly(no),
        accessibility_support(no),
        cost(0),
        route(unavailable)
    )
).

% 13. DECISION REASONING CHAIN
reasoning_chain(
    Zone,
    Chain
) :-
    zone_facts(
        Zone,
        Facts
    ),
    risk_explanation(
        Zone,
        Risk
    ),
    medical_explanation(
        Zone,
        Medical
    ),
    evacuation_explanation(
        Zone,
        Evacuation
    ),
    Chain =
        reasoning_chain(
            facts(Facts),
            risk(Risk),
            medical(Medical),
            evacuation(Evacuation)
        ).

% 14. COMPLETE ZONE EXPLANATION
zone_explanation(
    Zone,
    Explanation
) :-
    zone_decision(
        Zone,
        Decision
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
                Action
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
        ),
    reasoning_chain(
        Zone,
        ReasoningChain
    ),
    Explanation =
        explanation(
            zone(Zone),
            reasoning(
                ReasoningChain
            ),
            decision(
                risk_level(RiskLevel),
                risk_score(RiskScore),
                medical_priority(MedicalPriority),
                evacuation_priority(EvacuationPriority),
                priority_score(PriorityScore),
                action(Action)
            ),
            resources(
                resource_status(ResourceStatus),
                ambulance(Ambulance),
                hospital(Hospital),
                shelter(Shelter)
            ),
            reason(
                Reason
            )
        ).

% 15. ALL ZONE EXPLANATIONS
all_zone_explanations(
    Explanations
) :-
    findall(
        Explanation,
        (
            zone(Zone),
            once(
                zone_explanation(
                    Zone,
                    Explanation
                )
            )
        ),
        Explanations
    ).

% 16. HUMAN-READABLE EXPLANATION
human_explanation(
    Zone,
    Text
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
    ),
    primary_action(
        RiskLevel,
        MedicalPriority,
        EvacuationPriority,
        Action
    ),
    format(
        string(Text),
        'Zone ~w has ~w risk (score ~w), ~w medical priority and ~w evacuation priority. Recommended action: ~w.',
        [
            Zone,
            RiskLevel,
            RiskScore,
            MedicalPriority,
            EvacuationPriority,
            Action
        ]
    ).

% 17. FACT -> RULE -> DECISION SUMMARY
decision_trace(
    Zone,
    Trace
) :-
    zone_facts(
        Zone,
        Facts
    ),
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
    ),
    primary_action(
        RiskLevel,
        MedicalPriority,
        EvacuationPriority,
        Action
    ),
    Trace =
        trace(
            facts(Facts),
            inference(
                risk(
                    RiskLevel,
                    RiskScore
                ),
                medical_priority(
                    MedicalPriority
                ),
                evacuation_priority(
                    EvacuationPriority
                )
            ),
            decision(
                Action
            )
        ).

% 18. SYSTEM EXPLANATION
system_explanation(
    Explanation
) :-
    all_zone_explanations(
        Explanations
    ),
    length(
        Explanations,
        TotalZones
    ),
    Explanation =
        system_explanation(
            total_zones(TotalZones),
            zones(Explanations)
        ).