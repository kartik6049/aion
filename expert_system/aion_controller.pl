:- use_module(library(http/json)).

:- ensure_loaded('facts.pl').
:- ensure_loaded('rules.pl').
:- ensure_loaded('search.pl').
:- ensure_loaded('astar.pl').
:- ensure_loaded('resource_engine.pl').
:- ensure_loaded('decision_engine.pl').
:- ensure_loaded('explanation.pl').
:- ensure_loaded('response_planner.pl').

% AION COMPLETE PLAN

generate_complete_plan(Plan) :-
    once(
        generate_response_plan(
            response_plan(
                _Disaster,
                _PriorityOrder,
                _CriticalZones,
                _MedicalEmergencyZones,
                _ImmediateActionZones,
                _ResourceShortages,
                _Resources,
                _Metrics,
                zones(Plan)
            )
        )
    ).


% ============================================================
% AION RESULT
% ============================================================

generate_aion_result(
    Plan,
    Explanations
) :-
    generate_complete_plan(Plan),
    all_zone_explanations(Explanations).


% ============================================================
% HUMAN / ZONE REPORTS
% ============================================================

aion_zone_report(
    Zone,
    Explanation
) :-
    zone_explanation(
        Zone,
        Explanation
    ).


show_zone_report(Zone) :-
    human_explanation(
        Zone,
        Explanation
    ),
    writeln(Explanation).


show_all_zone_reports :-
    forall(
        zone(Zone),
        (
            human_explanation(
                Zone,
                Explanation
            ),
            writeln(Explanation),
            nl
        )
    ).


% ============================================================
% MAIN JSON API
% ============================================================

aion_json_result :-
    generate_complete_plan(Plan),
    plan_to_json(
        Plan,
        JsonPlan
    ),
    json_write_dict(
        current_output,
        aion_result{
            plan:JsonPlan
        }
    ).


% ============================================================
% PLAN -> JSON
% ============================================================

plan_to_json(
    [],
    []
).

plan_to_json(
    [
        zone_response(
            zone(Zone),
            Decision,
            Explanation
        )
        | Rest
    ],
    [
        zone_response_json{
            zone:Zone,
            decision:DecisionJSON,
            explanation:ExplanationJSON
        }
        | JsonRest
    ]
) :-
    decision_to_json(
        Decision,
        DecisionJSON
    ),
    explanation_wrapper_to_json(
        Explanation,
        ExplanationJSON
    ),
    plan_to_json(
        Rest,
        JsonRest
    ).


% ============================================================
% DECISION -> JSON
% ============================================================

decision_to_json(
    decision(
        decision(
            Zone,
            risk(RiskLevel, RiskScore),
            medical(MedicalPriority),
            evacuation(EvacuationPriority),
            priority_score(PriorityScore),
            action(Action),
            Ambulance,
            Hospital,
            Shelter,
            Resources,
            reason(Reason)
        )
    ),
    JSON
) :-
    ambulance_decision_to_json(
        Ambulance,
        AmbulanceJSON
    ),

    hospital_decision_to_json(
        Hospital,
        HospitalJSON
    ),

    shelter_decision_to_json(
        Shelter,
        ShelterJSON
    ),

    reason_to_json(
        Reason,
        ReasonJSON
    ),

    resources_to_json(
        Resources,
        ResourcesJSON
    ),

    JSON = decision_json{
        zone:Zone,

        risk:risk_json{
            level:RiskLevel,
            score:RiskScore
        },

        medical:MedicalPriority,

        evacuation:EvacuationPriority,

        priority_score:PriorityScore,

        action:Action,

        ambulance:AmbulanceJSON,

        hospital:HospitalJSON,

        shelter:ShelterJSON,

        resources:ResourcesJSON,

        reason:ReasonJSON
    }.


% ============================================================
% AMBULANCE DECISION -> JSON
% ============================================================

ambulance_decision_to_json(
    ambulance(
        Name,
        Zone,
        Path,
        Cost,
        Capability,
        Capacity
    ),
    ambulance_json{
        name:Name,
        zone:Zone,
        route:Path,
        cost:Cost,
        capability:Capability,
        capacity:Capacity
    }
).

ambulance_decision_to_json(
    none,
    ambulance_json{
        name:none
    }
).


% ============================================================
% HOSPITAL DECISION -> JSON
% ============================================================

hospital_decision_to_json(
    hospital(
        Name,
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
    hospital_json{
        name:Name,
        zone:Zone,
        hospital_zone:HospitalZone,
        route:Path,
        cost:Cost,
        patients:Patients,
        capacity:TotalCapacity,
        available_capacity:AvailableCapacity,
        status:Status,
        capability:Capability
    }
).

hospital_decision_to_json(
    none,
    hospital_json{
        name:none
    }
).


% ============================================================
% SHELTER DECISION -> JSON
% ============================================================

shelter_decision_to_json(
    shelter(
        Name,
        Zone,
        ShelterZone,
        Path,
        Cost,
        People,
        Capacity,
        AvailableCapacity,
        Status,
        MedicalSupport,
        FamilyFriendly,
        AccessibilitySupport
    ),
    shelter_json{
        name:Name,
        zone:Zone,
        shelter_zone:ShelterZone,
        route:Path,
        cost:Cost,
        people:People,
        capacity:Capacity,
        available_capacity:AvailableCapacity,
        status:Status,
        medical_support:MedicalSupport,
        family_friendly:FamilyFriendly,
        accessibility_support:AccessibilitySupport
    }
).

shelter_decision_to_json(
    none,
    shelter_json{
        name:none
    }
).


% ============================================================
% DECISION REASON -> JSON
% ============================================================

reason_to_json(
    reason(
        risk_level(RiskLevel),
        risk_score(RiskScore),
        medical_priority(MedicalPriority),
        evacuation_priority(EvacuationPriority),
        recommended_action(Action)
    ),
    reason_json{
        risk_level:RiskLevel,
        risk_score:RiskScore,
        medical_priority:MedicalPriority,
        evacuation_priority:EvacuationPriority,
        recommended_action:Action
    }
).


% ============================================================
% DECISION RESOURCES -> JSON
% ============================================================

resources_to_json(
    resources(
        resources(
            ambulance(AmbulanceStatus),
            hospital(HospitalStatus),
            shelter(ShelterStatus)
        )
    ),
    resources_json{
        ambulance:AmbulanceStatus,
        hospital:HospitalStatus,
        shelter:ShelterStatus
    }
).


% ============================================================
% EXPLANATION DECISION -> JSON
% ============================================================

explanation_decision_to_json(
    decision(
        risk_level(RiskLevel),
        risk_score(RiskScore),
        medical_priority(MedicalPriority),
        evacuation_priority(EvacuationPriority),
        priority_score(PriorityScore),
        action(Action)
    ),
    explanation_decision_json{
        risk_level:RiskLevel,
        risk_score:RiskScore,
        medical_priority:MedicalPriority,
        evacuation_priority:EvacuationPriority,
        priority_score:PriorityScore,
        action:Action
    }
).


% ============================================================
% EXPLANATION RESOURCES -> JSON
% ============================================================

explanation_resources_to_json(
    resources(
        resource_status(
            resources(
                ambulance(AmbulanceStatus),
                hospital(HospitalStatus),
                shelter(ShelterStatus)
            )
        ),
        Ambulance,
        Hospital,
        Shelter
    ),
    explanation_resources_json{
        status:resources_status_json{
            ambulance:AmbulanceStatus,
            hospital:HospitalStatus,
            shelter:ShelterStatus
        },
        ambulance:AmbulanceJSON,
        hospital:HospitalJSON,
        shelter:ShelterJSON
    }
) :-
    explanation_ambulance_to_json(
        Ambulance,
        AmbulanceJSON
    ),

    explanation_hospital_to_json(
        Hospital,
        HospitalJSON
    ),

    explanation_shelter_to_json(
        Shelter,
        ShelterJSON
    ).


% ============================================================
% EXPLANATION RESOURCE JSON SERIALIZERS
% ============================================================

explanation_ambulance_to_json(
    ambulance(
        ambulance(
            Name,
            Zone,
            Path,
            Cost,
            Capability,
            Capacity
        )
    ),
    ambulance_json{
        name:Name,
        zone:Zone,
        route:Path,
        cost:Cost,
        capability:Capability,
        capacity:Capacity
    }
).
explanation_ambulance_to_json(
    ambulance(none),
    ambulance_json{
        name:none
    }).

explanation_hospital_to_json(
    hospital(
        hospital(
            Name,
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
    ),
    hospital_json{
        name:Name,
        zone:Zone,
        hospital_zone:HospitalZone,
        route:Path,
        cost:Cost,
        patients:Patients,
        capacity:TotalCapacity,
        available_capacity:AvailableCapacity,
        status:Status,
        capability:Capability
    }
).
explanation_hospital_to_json(
    hospital(none),
    hospital_json{
        name:none
    }).

explanation_shelter_to_json(
    shelter(
        shelter(
            Name,
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
    ),
    shelter_json{
        name:Name,
        zone:Zone,
        shelter_zone:ShelterZone,
        route:Path,
        cost:Cost,
        people:People,
        capacity:TotalCapacity,
        available_capacity:AvailableCapacity,
        status:Status,
        medical_support:MedicalSupport,
        family_friendly:FamilyFriendly,
        accessibility_support:AccessibilitySupport
    }
).
explanation_shelter_to_json(
    shelter(none),
    shelter_json{
        name:none
    }).

% ============================================================
% EXPLANATION WRAPPER -> JSON
% ============================================================

explanation_wrapper_to_json(
    explanation(
        explanation(
            zone(Zone),
            Reasoning,
            Decision,
            Resources,
            reason(Reason)
        )
    ),
    JSON
) :-
    explanation_decision_to_json(
        Decision,
        DecisionJSON
    ),

    reasoning_to_json(
        Reasoning,
        ReasoningJSON
    ),

    explanation_resources_to_json(
        Resources,
        ResourcesJSON
    ),

    reason_to_json(
        Reason,
        ReasonJSON
    ),

    JSON = explanation_json{
        zone:Zone,
        reasoning:ReasoningJSON,
        decision:DecisionJSON,
        resources:ResourcesJSON,
        reason:ReasonJSON
    }.


% ============================================================
% FACTS -> JSON
% ============================================================

facts_to_json(
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
    ),
    facts_json{
        population:Population,

        evacuation_population:EvacuationPopulation,

        vulnerable_population:vulnerable_json{
            children:Children,
            elderly:Elderly,
            disabled:Disabled
        },

        medical_cases:medical_cases_json{
            critical:CriticalCases,
            serious:SeriousCases,
            minor:MinorCases
        },

        zone_condition:zone_condition_json{
            risk_level:RiskLevel,
            flood_level:FloodLevel,
            structural_damage:StructuralDamage,
            population_at_risk:PopulationAtRisk,
            urgency:Urgency
        }
    }
).


% ============================================================
% RISK -> JSON
% ============================================================

risk_to_json(
    risk(
        risk_assessment(
            level(Level),
            score(Score)
        )
    ),
    risk_json{
        level:Level,
        score:Score
    }
).


% ============================================================
% MEDICAL -> JSON
% ============================================================

medical_to_json(
    medical(
        medical_assessment(
            total_cases(TotalCases),
            critical_cases(CriticalCases),
            serious_cases(SeriousCases),
            minor_cases(MinorCases),
            priority(Priority)
        )
    ),
    medical_json{
        total_cases:TotalCases,
        critical_cases:CriticalCases,
        serious_cases:SeriousCases,
        minor_cases:MinorCases,
        priority:Priority
    }
).


% ============================================================
% EVACUATION -> JSON
% ============================================================

evacuation_to_json(
    evacuation(
        evacuation_assessment(
            priority(Priority),
            people(People)
        )
    ),
    evacuation_json{
        priority:Priority,
        people:People
    }
).


% ============================================================
% REASONING -> JSON
% ============================================================
reasoning_to_json(
    reasoning(
        reasoning_chain(
            facts(
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
                )
            ),
            risk(
                risk_assessment(
                    level(RiskAssessmentLevel),
                    score(RiskScore)
                )
            ),
            medical(
                medical_assessment(
                    total_cases(TotalCases),
                    critical_cases(MedicalCriticalCases),
                    serious_cases(MedicalSeriousCases),
                    minor_cases(MedicalMinorCases),
                    priority(MedicalPriority)
                )
            ),
            evacuation(
                evacuation_assessment(
                    priority(EvacuationPriority),
                    people(EvacuationPeople)
                )
            )
        )
    ),
    reasoning_json{
        facts:facts_json{
            population:Population,
            evacuation_population:EvacuationPopulation,
            vulnerable_population:vulnerable_json{
                children:Children,
                elderly:Elderly,
                disabled:Disabled
            },
            medical_cases:medical_cases_json{
                critical:CriticalCases,
                serious:SeriousCases,
                minor:MinorCases
            },
            zone_condition:zone_condition_json{
                risk_level:RiskLevel,
                flood_level:FloodLevel,
                structural_damage:StructuralDamage,
                population_at_risk:PopulationAtRisk,
                urgency:Urgency
            }
        },
        risk:risk_json{
            level:RiskAssessmentLevel,
            score:RiskScore
        },
        medical:medical_json{
            total_cases:TotalCases,
            critical_cases:MedicalCriticalCases,
            serious_cases:MedicalSeriousCases,
            minor_cases:MedicalMinorCases,
            priority:MedicalPriority
        },
        evacuation:evacuation_json{
            priority:EvacuationPriority,
            people:EvacuationPeople
        }
    }
).


% ============================================================
% ZONE JSON
% ============================================================

aion_zone_json(Zone) :-
    once(
        zone_response(
            Zone,
            zone_response(
                zone(Zone),
                decision(Decision),
                explanation(Explanation)
            )
        )
    ),
    decision_to_json(
        decision(Decision),
        DecisionJSON
    ),
    explanation_wrapper_to_json(
        explanation(Explanation),
        ExplanationJSON
    ),
    json_write_dict(
        current_output,
        zone_report_json{
            zone:Zone,
            decision:DecisionJSON,
            explanation:ExplanationJSON
        }
    ).


% Entry point used by the API. Always succeeds: an unknown zone is reported
% as a JSON error object instead of a failed goal.
aion_zone_response(Zone) :-
    (   zone(Zone)
    ->  aion_zone_json(Zone)
    ;   json_write_dict(
            current_output,
            error_json{
                error:"zone_not_found",
                zone:Zone
            }
        )
    ).

% ============================================================
% SYSTEM JSON
% ============================================================

aion_system_json :-
    generate_response_plan(
        response_plan(
            Disaster,
            PriorityOrder,
            CriticalZones,
            MedicalEmergencyZones,
            ImmediateActionZones,
            ResourceShortages,
            Resources,
            Metrics,
            zones(_)
        )
    ),

    system_disaster_to_json(
        Disaster,
        DisasterJSON
    ),

    system_priority_order_to_json(
        PriorityOrder,
        PriorityOrderJSON
    ),
    system_zone_list_to_json(
        CriticalZones,
        CriticalZonesJSON
    ),
    system_medical_zone_list_to_json(
        MedicalEmergencyZones,
        MedicalEmergencyZonesJSON
    ),
    system_immediate_zone_list_to_json(
        ImmediateActionZones,
        ImmediateActionZonesJSON
    ),

    system_shortages_to_json(
        ResourceShortages,
        ShortagesJSON
    ),

    system_resources_to_json(
        Resources,
        ResourcesJSON
    ),

    system_metrics_to_json(
        Metrics,
        MetricsJSON
    ),

    json_write_dict(
        current_output,
        system_json{
            disaster:DisasterJSON,
            priority_order:PriorityOrderJSON,
            critical_zones:CriticalZonesJSON,
            medical_emergency_zones:MedicalEmergencyZonesJSON,
            immediate_action_zones:ImmediateActionZonesJSON,
            resource_shortages:ShortagesJSON,
            resources:ResourcesJSON,
            metrics:MetricsJSON
        }
    ).
    

% ============================================================
% SYSTEM DISASTER -> JSON
% ============================================================

system_disaster_to_json(
    disaster(
        disaster(
            type(Type),
            severity(Severity)
        )
    ),
    disaster_json{
        type:Type,
        severity:Severity
    }
).

% ============================================================
% SYSTEM PRIORITY ORDER -> JSON
% ============================================================

system_priority_order_to_json(
    priority_order(Zones),
    Zones
).

system_priority_order_to_json(
    Zones,
    Zones
) :-
    is_list(Zones).


% ============================================================
% SYSTEM CRITICAL ZONES -> JSON
% ============================================================

system_zone_list_to_json(
    critical_zones(Zones),
    Zones
).


% ============================================================
% SYSTEM MEDICAL EMERGENCY ZONES -> JSON
% ============================================================

system_medical_zone_list_to_json(
    medical_emergency_zones(Zones),
    Zones
).


% ============================================================
% SYSTEM IMMEDIATE ACTION ZONES -> JSON
% ============================================================

system_immediate_zone_list_to_json(
    immediate_action_zones(Zones),
    Zones
).

% ============================================================
% SYSTEM SHORTAGES -> JSON
% ============================================================

system_shortages_to_json(
    resource_shortages(Shortages),
    ShortagesJSON
) :-
    !,
    system_shortages_to_json_list(
        Shortages,
        ShortagesJSON
    ).

system_shortages_to_json(
    shortage_list(Shortages),
    ShortagesJSON
) :-
    !,
    system_shortages_to_json_list(
        Shortages,
        ShortagesJSON
    ).

system_shortages_to_json(
    Shortages,
    ShortagesJSON
) :-
    is_list(Shortages),
    !,
    system_shortages_to_json_list(
        Shortages,
        ShortagesJSON
    ).


system_shortages_to_json_list(
    [],
    []
).

system_shortages_to_json_list(
    [shortage(Type,Zone)|Rest],
    [
        shortage_json{
            type:Type,
            zone:Zone
        }
        | JsonRest
    ]
) :-
    system_shortages_to_json_list(
        Rest,
        JsonRest
    ).


% ============================================================
% SYSTEM RESOURCES -> JSON
% ============================================================

system_resources_to_json(
    resources(
        response_resources(
            resources(
                ambulances(Ambulances),
                hospitals(Hospitals),
                shelters(Shelters)
            )
        )
    ),
    resources_summary_json{
        ambulances:AmbulancesJSON,
        hospitals:HospitalsJSON,
        shelters:SheltersJSON
    }
) :-
    system_ambulances_to_json(
        Ambulances,
        AmbulancesJSON
    ),
    system_hospitals_to_json(
        Hospitals,
        HospitalsJSON
    ),
    system_shelters_to_json(
        Shelters,
        SheltersJSON
    ).


% ============================================================
% AMBULANCES -> JSON
% ============================================================

system_ambulances_to_json(
    [],
    []
).

system_ambulances_to_json(
    [
        ambulance_info(
            Name,
            Location,
            Status,
            Capability,
            Capacity
        )
        | Rest
    ],
    [
        ambulance_json{
            name:Name,
            location:Location,
            status:Status,
            capability:Capability,
            capacity:Capacity
        }
        | JsonRest
    ]
) :-
    system_ambulances_to_json(
        Rest,
        JsonRest
    ).


% ============================================================
% HOSPITALS -> JSON
% ============================================================

system_hospitals_to_json(
    [],
    []
).

system_hospitals_to_json(
    [
        hospital_info(
            Name,
            Location,
            Capacity,
            EmergencyCapacity,
            Status,
            Capability
        )
        | Rest
    ],
    [
        hospital_json{
            name:Name,
            location:Location,
            capacity:Capacity,
            emergency_capacity:EmergencyCapacity,
            status:Status,
            capability:Capability
        }
        | JsonRest
    ]
) :-
    system_hospitals_to_json(
        Rest,
        JsonRest
    ).


% ============================================================
% SHELTERS -> JSON
% ============================================================

system_shelters_to_json(
    [],
    []
).

system_shelters_to_json(
    [
        shelter_info(
            Name,
            Location,
            Capacity,
            Occupancy,
            Status
        )
        | Rest
    ],
    [
        shelter_json{
            name:Name,
            location:Location,
            capacity:Capacity,
            occupancy:Occupancy,
            status:Status
        }
        | JsonRest
    ]
) :-
    system_shelters_to_json(
        Rest,
        JsonRest
    ).


% ============================================================
% SYSTEM METRICS -> JSON
% ============================================================

system_metrics_to_json(
    metrics(
        metrics(
            total_zones(TotalZones),
            critical_zones(CriticalZones),
            medical_emergency_zones(MedicalEmergencyZones),
            immediate_evacuation_zones(ImmediateEvacuationZones),
            resource_shortages(ResourceShortages)
        )
    ),
    metrics_json{
        total_zones:TotalZones,
        critical_zones:CriticalZones,
        medical_emergency_zones:MedicalEmergencyZones,
        immediate_evacuation_zones:ImmediateEvacuationZones,
        resource_shortages:ResourceShortages
    }
).


% ============================================================
% AION HEALTH CHECK
% ============================================================

aion_health_check :-
    current_disaster(
        Disaster,
        Severity
    ),

    findall(
        Zone,
        zone(Zone),
        Zones
    ),

    length(
        Zones,
        ZoneCount
    ),

    json_write_dict(
        current_output,
        health_check_json{
            status:"ok",
            system:"AION",
            disaster:Disaster,
            severity:Severity,
            reasoning_engine:"online",
            zones_loaded:ZoneCount
        }
    ).
% ============================================================
% FACTS JSON (read-only view of the input facts)
% ============================================================
% Prints the facts the engine reasons over, exactly as stored in facts.pl,
% so that people can check them against the decisions. Nothing here is
% derived or computed beyond looking facts up.

aion_facts_json :-
    findall(Z, zone(Z), ZoneNames),
    findall(ZoneJSON, (member(Z, ZoneNames), facts_zone_json(Z, ZoneJSON)), Zones),
    findall(H, facts_hospital_json(H), Hospitals),
    findall(S, facts_shelter_json(S), Shelters),
    findall(A, facts_ambulance_json(A), Ambulances),
    findall(R, facts_road_json(R), Roads),
    facts_scenario_json(Scenario),
    json_write_dict(
        current_output,
        facts_json{
            scenario:Scenario,
            zones:Zones,
            hospitals:Hospitals,
            shelters:Shelters,
            ambulances:Ambulances,
            roads:Roads
        }
    ).

facts_scenario_json(Scenario) :-
    ( scenario_name(Name) -> true ; Name = null ),
    ( scenario_version(Version) -> true ; Version = null ),
    ( scenario_description(Description) -> true ; Description = null ),
    ( current_disaster(Type, Severity) -> true ; Type = null, Severity = null ),
    Scenario = scenario_json{
        name:Name,
        version:Version,
        description:Description,
        disaster_type:Type,
        disaster_severity:Severity
    }.

facts_zone_json(Zone, Json) :-
    ( population(Zone, Population) -> true ; Population = null ),
    ( evacuation_population(Zone, Evacuation) -> true ; Evacuation = null ),
    (   vulnerable_population(Zone, Children, Elderly, Disabled)
    ->  true
    ;   Children = null, Elderly = null, Disabled = null
    ),
    (   medical_cases(Zone, Critical, Serious, Minor)
    ->  true
    ;   Critical = null, Serious = null, Minor = null
    ),
    (   zone_condition(Zone, Risk, Flood, Structural, AtRisk, Urgency)
    ->  true
    ;   Risk = null, Flood = null, Structural = null,
        AtRisk = null, Urgency = null
    ),
    (   coordinates(Zone, X, Y)
    ->  true
    ;   X = null, Y = null
    ),
    Json = zone_facts_json{
        zone:Zone,
        population:Population,
        evacuation_population:Evacuation,
        children:Children,
        elderly:Elderly,
        disabled:Disabled,
        critical_cases:Critical,
        serious_cases:Serious,
        minor_cases:Minor,
        risk_level:Risk,
        flood_level:Flood,
        structural_damage:Structural,
        population_at_risk:AtRisk,
        urgency:Urgency,
        x:X,
        y:Y
    }.

facts_hospital_json(Json) :-
    hospital_state(Name, Zone, Total, Available, Status, Capability),
    Json = hospital_facts_json{
        name:Name,
        zone:Zone,
        total_capacity:Total,
        available_capacity:Available,
        status:Status,
        capability:Capability
    }.

facts_shelter_json(Json) :-
    shelter_state(Name, Zone, Total, Available, Status),
    (   shelter_features(Name, Medical, Family, Accessibility)
    ->  true
    ;   Medical = null, Family = null, Accessibility = null
    ),
    Json = shelter_facts_json{
        name:Name,
        zone:Zone,
        total_capacity:Total,
        available_capacity:Available,
        status:Status,
        medical_support:Medical,
        family_friendly:Family,
        accessibility_support:Accessibility
    }.

facts_ambulance_json(Json) :-
    ambulance_state(Name, Zone, Status, Capability, Capacity),
    Json = ambulance_facts_json{
        name:Name,
        zone:Zone,
        status:Status,
        capability:Capability,
        capacity:Capacity
    }.

facts_road_json(Json) :-
    road_state(Name, From, To, Distance, Status, Risk),
    ( road_capacity(Name, Capacity) -> true ; Capacity = null ),
    ( road_congestion_factor(Name, Factor) -> true ; Factor = null ),
    Json = road_facts_json{
        name:Name,
        from:From,
        to:To,
        distance:Distance,
        status:Status,
        risk:Risk,
        capacity:Capacity,
        congestion_factor:Factor
    }.
