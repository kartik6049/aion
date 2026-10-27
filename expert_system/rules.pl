:- ensure_loaded('facts.pl').


% 1. DISASTER SEVERITY
disaster_severity_score(low, 1).
disaster_severity_score(medium, 2).
disaster_severity_score(high, 3).
disaster_severity_score(critical, 4).


current_disaster_score(Score) :-
   current_disaster(_, Severity),
   disaster_severity_score(Severity, Score).


% 2. FLOOD SEVERITY SCORE
flood_level_score(low, 1).
flood_level_score(medium, 2).
flood_level_score(high, 3).
flood_level_score(severe, 4).


zone_flood_score(Zone, Score) :-
   zone_condition(
       Zone,
       _Risk,
       FloodLevel,
       _Damage,
       _PopulationAtRisk,
       _Urgency
   ),
   flood_level_score(FloodLevel, Score).


% 3. STRUCTURAL DAMAGE SCORE
damage_score(none, 0).
damage_score(low, 1).
damage_score(medium, 2).
damage_score(high, 3).
damage_score(severe, 4).


zone_damage_score(Zone, Score) :-
   zone_condition(
       Zone,
       _Risk,
       _Flood,
       Damage,
       _PopulationAtRisk,
       _Urgency
   ),
   damage_score(Damage, Score).


% 4. URGENCY SCORE
urgency_score(low, 1).
urgency_score(medium, 2).
urgency_score(high, 3).
urgency_score(critical, 4).


zone_urgency_score(Zone, Score) :-
   zone_condition(
       Zone,
       _Risk,
       _Flood,
       _Damage,
       _PopulationAtRisk,
       Urgency
   ),
   urgency_score(Urgency, Score).


% 5. POPULATION AT RISK SCORE
population_risk_score(People, 4) :-
   People >= 100.


population_risk_score(People, 3) :-
   People >= 50,
   People < 100.


population_risk_score(People, 2) :-
   People >= 20,
   People < 50.


population_risk_score(People, 1) :-
   People < 20.


zone_population_risk_score(Zone, Score) :-
   zone_condition(
       Zone,
       _Risk,
       _Flood,
       _Damage,
       PopulationAtRisk,
       _Urgency
   ),
   population_risk_score(
       PopulationAtRisk,
       Score
   ).


% 6. VULNERABLE POPULATION SCORE
vulnerable_population_total(
   Zone,
   Total
) :-
   vulnerable_population(
       Zone,
       Children,
       Elderly,
       Disabled
   ),
   Total is Children + Elderly + Disabled.


vulnerable_population_score(Zone, 4) :-
   vulnerable_population_total(Zone, Total),
   Total >= 60.


vulnerable_population_score(Zone, 3) :-
   vulnerable_population_total(Zone, Total),
   Total >= 40,
   Total < 60.


vulnerable_population_score(Zone, 2) :-
   vulnerable_population_total(Zone, Total),
   Total >= 20,
   Total < 40.


vulnerable_population_score(Zone, 1) :-
   vulnerable_population_total(Zone, Total),
   Total < 20.


% 7. MEDICAL CASE ANALYSIS
medical_case_total(
   Zone,
   Total
) :-
   medical_cases(
       Zone,
       Critical,
       Serious,
       Minor
   ),
   Total is Critical + Serious + Minor.


critical_case_score(Zone, 4) :-
   medical_cases(
       Zone,
       Critical,
       _Serious,
       _Minor
   ),
   Critical >= 10.


critical_case_score(Zone, 3) :-
   medical_cases(
       Zone,
       Critical,
       _Serious,
       _Minor
   ),
   Critical >= 5,
   Critical < 10.


critical_case_score(Zone, 2) :-
   medical_cases(
       Zone,
       Critical,
       _Serious,
       _Minor
   ),
   Critical >= 1,
   Critical < 5.


critical_case_score(Zone, 1) :-
   medical_cases(
       Zone,
       0,
       _Serious,
       _Minor
   ).


% 8. HOSPITAL CAPACITY ANALYSIS
hospital_available(Hospital) :-
   hospital_state(
       Hospital,
       _Zone,
       _TotalCapacity,
       AvailableCapacity,
       Status,
       _Capability
   ),
   AvailableCapacity > 0,
   hospital_operational_status(Status).


hospital_operational_status(operational).
hospital_operational_status(limited).


% 9. HOSPITAL CAPACITY LEVEL
hospital_capacity_level(
   Hospital,
   high
) :-
   hospital_state(
       Hospital,
       _Zone,
       TotalCapacity,
       AvailableCapacity,
       _Status,
       _Capability
   ),
   AvailableCapacity > 0,
   Percentage is
       (AvailableCapacity * 100) / TotalCapacity,
   Percentage >= 50.


hospital_capacity_level(
   Hospital,
   medium
) :-
   hospital_state(
       Hospital,
       _Zone,
       TotalCapacity,
       AvailableCapacity,
       _Status,
       _Capability
   ),
   AvailableCapacity > 0,
   Percentage is
       (AvailableCapacity * 100) / TotalCapacity,
   Percentage >= 20,
   Percentage < 50.


hospital_capacity_level(
   Hospital,
   low
) :-
   hospital_state(
       Hospital,
       _Zone,
       TotalCapacity,
       AvailableCapacity,
       _Status,
       _Capability
   ),
   AvailableCapacity > 0,
   Percentage is
       (AvailableCapacity * 100) / TotalCapacity,
   Percentage < 20.


% 10. HOSPITAL CAPACITY FOR ZONE
zone_has_medical_capacity(Zone) :-
   hospital_state(
       _Hospital,
       Zone,
       _TotalCapacity,
       AvailableCapacity,
       Status,
       _Capability
   ),
   AvailableCapacity > 0,
   hospital_operational_status(Status).


% 11. MEDICAL PRIORITY
medical_priority(Zone, critical) :-
   medical_cases(Zone, CriticalCases, _, _),
   CriticalCases >= 10,
   !.


medical_priority(Zone, high) :-
   medical_cases(Zone, CriticalCases, _SeriousCases, _),
   CriticalCases >= 5,
   CriticalCases < 10,
   !.


medical_priority(Zone, high) :-
   medical_cases(Zone, CriticalCases, SeriousCases, _),
   SeriousCases >= 15,
   CriticalCases < 5,
   !.


medical_priority(Zone, medium) :-
   medical_cases(Zone, CriticalCases, SeriousCases, MinorCases),
   TotalCases is CriticalCases + SeriousCases + MinorCases,
   TotalCases > 0,
   CriticalCases < 5,
   SeriousCases < 15,
   !.


medical_priority(Zone, low) :-
   medical_cases(Zone, CriticalCases, SeriousCases, MinorCases),
   TotalCases is CriticalCases + SeriousCases + MinorCases,
   TotalCases =< 0.




% 12. MULTI-FACTOR ZONE RISK SCORE
zone_risk_score(
   Zone,
   Score
) :-
   current_disaster_score(DisasterScore),
   zone_flood_score(
       Zone,
       FloodScore
   ),
   zone_damage_score(
       Zone,
       DamageScore
   ),
   zone_population_risk_score(
       Zone,
       PopulationScore
   ),
   vulnerable_population_score(
       Zone,
       VulnerableScore
   ),
   critical_case_score(
       Zone,
       MedicalScore
   ),
   zone_urgency_score(
       Zone,
       UrgencyScore
   ),
   Score is
       DisasterScore
       + FloodScore
       + DamageScore
       + PopulationScore
       + VulnerableScore
       + MedicalScore
       + UrgencyScore.


% 13. RISK CLASSIFICATION
critical_risk_zone(Zone) :-
   zone_risk_score(Zone, Score),
   Score >= 23.


high_risk_zone(Zone) :-
   zone_risk_score(Zone, Score),
   Score >= 17,
   Score < 23.


medium_risk_zone(Zone) :-
   zone_risk_score(Zone, Score),
   Score >= 11,
   Score < 17.


low_risk_zone(Zone) :-
   zone_risk_score(Zone, Score),
   Score < 11.


% 14. RISK LEVEL PREDICATE
zone_risk_level(Zone, critical) :-
   critical_risk_zone(Zone).


zone_risk_level(Zone, high) :-
   high_risk_zone(Zone).


zone_risk_level(Zone, medium) :-
   medium_risk_zone(Zone).


zone_risk_level(Zone, low) :-
   low_risk_zone(Zone).


% 15. EVACUATION PRIORITY SCORE
medical_priority_score(critical, 4).
medical_priority_score(high, 3).
medical_priority_score(medium, 2).
medical_priority_score(low, 1).


evacuation_priority_score(
   Zone,
   Score
) :-
   zone_risk_score(
       Zone,
       RiskScore
   ),
   zone_urgency_score(
       Zone,
       UrgencyScore
   ),
   vulnerable_population_score(
       Zone,
       VulnerableScore
   ),
   medical_priority(
       Zone,
       MedicalPriority
   ),
   medical_priority_score(
       MedicalPriority,
       MedicalScore
   ),
   Score is
       RiskScore
       + UrgencyScore
       + VulnerableScore
       + MedicalScore.


% 16. EVACUATION PRIORITY
evacuation_priority(
   Zone,
   critical
) :-
   zone_risk_level(
       Zone,
       critical
   ),
   !.


evacuation_priority(
   Zone,
   critical
) :-
   medical_priority(
       Zone,
       critical
   ),
   !.


evacuation_priority(
   Zone,
   high
) :-
   zone_risk_level(
       Zone,
       high
   ),
   !.


evacuation_priority(
   Zone,
   high
) :-
   medical_priority(
       Zone,
       high
   ),
   !.


evacuation_priority(
   Zone,
   medium
) :-
   zone_risk_level(
       Zone,
       medium
   ),
   !.


evacuation_priority(
   Zone,
   medium
) :-
   medical_priority(
       Zone,
       medium
   ),
   !.


evacuation_priority(
   Zone,
   low
) :-
   zone_risk_level(
       Zone,
       low
   ).


% 17. EMERGENCY ZONE
emergency_zone(Zone) :-
   critical_risk_zone(Zone).


emergency_zone(Zone) :-
   evacuation_priority(
       Zone,
       critical
   ).


% 18. MEDICAL ATTENTION ZONE (medical priority critical or high)
% Renamed from medical_emergency_zone/1, which response_planner.pl also
% defines (critical only). Loading both silently replaced this definition.
medical_attention_zone(Zone) :-
   medical_priority(
       Zone,
       critical
   ).


medical_attention_zone(Zone) :-
   medical_priority(
       Zone,
       high
   ).


% 19. SHELTER PRESSURE
% Shelters form a city-wide pool: the available places of every operational
% shelter are summed, regardless of the zone that is asking.
shelter_capacity_for_zone(
   _Zone,
   TotalAvailable
) :-
   findall(
       Available,
       (
           shelter_state(
               _Shelter,
               _ShelterZone,
               _TotalCapacity,
               Available,
               Status
           ),
           shelter_operational_status(Status)
       ),
       Capacities
   ),
   sum_list(
       Capacities,
       TotalAvailable
   ).


shelter_operational_status(operational).
shelter_operational_status(limited).


zone_shelter_pressure(
   Zone,
   adequate
) :-
   evacuation_population(
       Zone,
       People
   ),
   shelter_capacity_for_zone(
       Zone,
       Available
   ),
   Available >= People.


zone_shelter_pressure(
   Zone,
   critical
) :-
   evacuation_population(
       Zone,
       People
   ),
   shelter_capacity_for_zone(
       Zone,
       Available
   ),
   Available < People.


% 20. RESOURCE SHORTAGE DETECTION
hospital_capacity_shortage(Zone) :-
   medical_case_total(
       Zone,
       MedicalCases
   ),
   MedicalCases > 0,
   \+ zone_has_medical_capacity(Zone).


evacuation_capacity_shortage(Zone) :-
   zone_shelter_pressure(
       Zone,
       critical
   ).


% 21. OPERATOR OVERRIDE
effective_ambulance(
   Zone,
   Ambulance
) :-
   operator_override(
       Zone,
       ambulance,
       Ambulance
   ).


effective_ambulance(
   Zone,
   Ambulance
) :-
   \+ operator_override(
       Zone,
       ambulance,
       _
   ),
   available_ambulance_for_zone(
       Zone,
       Ambulance
   ).
% This predicate is intentionally kept as an interface point.
% The resource engine will provide the actual ambulance selection logic.
available_ambulance_for_zone(
   _Zone,
   _Ambulance
) :-
   fail.


% 22. SYSTEM HEALTH CHECKS
hospital_capacity_valid(Hospital) :-
   hospital_state(
       Hospital,
       _Zone,
       TotalCapacity,
       AvailableCapacity,
       _Status,
       _Capability
   ),
   TotalCapacity > 0,
   AvailableCapacity >= 0,
   AvailableCapacity =< TotalCapacity.


shelter_capacity_valid(Shelter) :-
   shelter_state(
       Shelter,
       _Zone,
       TotalCapacity,
       AvailableCapacity,
       _Status
   ),
   TotalCapacity > 0,
   AvailableCapacity >= 0,
   AvailableCapacity =< TotalCapacity.


ambulance_state_valid(Ambulance) :-
   ambulance_state(
       Ambulance,
       _Location,
       _Status,
       _Capability,
       Capacity
   ),
   Capacity > 0.


% 23. ZONE EVALUATION
evaluate_zone(
   Zone,
   evaluation(
       Zone,
       RiskLevel,
       RiskScore,
       MedicalPriority,
       EvacuationPriority
   )
) :-
   zone(
       Zone
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
   ).


% 24. EVALUATE ALL ZONES
evaluate_all_zones(
   Evaluations
) :-
   findall(
       Evaluation,
       evaluate_zone(
           _Zone,
           Evaluation
       ),
       Evaluations
   ).