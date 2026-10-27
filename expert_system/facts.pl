% DYNAMIC STATE
:- dynamic current_disaster/2.
:- dynamic zone_condition/6.
:- dynamic evacuation_population/2.
:- dynamic vulnerable_population/4.
:- dynamic hospital_state/6.
:- dynamic shelter_state/5.
:- dynamic ambulance_state/5.
:- dynamic road_state/6.
:- dynamic operator_override/3.
:- dynamic medical_cases/4.
:- dynamic committed/3.      % committed(Kind, Resource, Amount) while allocating
:- dynamic decision_cache/2.  % decision_cache(Zone, Decision) once allocated
:- dynamic road_congestion_factor/2.

% current_disaster(Type, Severity).
current_disaster(flood, high).
% Supported disaster types: flood, earthquake, cyclone, wildfire, industrial_accident
% ZONES
zone('Riverside').
zone('Downtown').
zone('Midtown').
zone('Northside').
zone('Lakeside').
zone('Eastwood').
zone('Hillview').
zone('Westend').
zone('Greenfield').
zone('Oldtown').

% TOTAL POPULATION
population('Riverside', 2500).
population('Downtown', 1800).
population('Midtown', 3200).
population('Northside', 1200).
population('Lakeside', 2100).
population('Eastwood', 1600).
population('Hillview', 2800).
population('Westend', 1900).
population('Greenfield', 2300).
population('Oldtown', 1400).

% CURRENT EVACUATION POPULATION
evacuation_population('Riverside', 40).
evacuation_population('Downtown', 25).
evacuation_population('Midtown', 150).
evacuation_population('Northside', 80).
evacuation_population('Lakeside', 110).
evacuation_population('Eastwood', 55).
evacuation_population('Hillview', 130).
evacuation_population('Westend', 35).
evacuation_population('Greenfield', 95).
evacuation_population('Oldtown', 20).

% ZONE CONDITION
zone_condition(
    'Riverside',
    medium,
    high,
    low,
    40,
    medium
).

zone_condition(
    'Downtown',
    medium,
    medium,
    low,
    25,
    medium
).

zone_condition(
    'Midtown',
    critical,
    severe,
    medium,
    150,
    critical
).

zone_condition(
    'Northside',
    high,
    high,
    low,
    80,
    high
).

zone_condition(
    'Lakeside',
    high,
    severe,
    medium,
    110,
    high
).

zone_condition(
    'Eastwood',
    medium,
    medium,
    low,
    55,
    medium
).

zone_condition(
    'Hillview',
    critical,
    high,
    medium,
    130,
    critical
).

zone_condition(
    'Westend',
    low,
    low,
    none,
    35,
    low
).

zone_condition(
    'Greenfield',
    high,
    high,
    medium,
    95,
    high
).

zone_condition(
    'Oldtown',
    low,
    low,
    low,
    20,
    low
).

% VULNERABLE POPULATION
vulnerable_population(
    'Riverside',
    8,
    10,
    3
).

vulnerable_population(
    'Downtown',
    5,
    6,
    2
).

vulnerable_population(
    'Midtown',
    30,
    25,
    10
).

vulnerable_population(
    'Northside',
    15,
    12,
    5
).

vulnerable_population(
    'Lakeside',
    20,
    18,
    7
).

vulnerable_population(
    'Eastwood',
    10,
    9,
    4
).

vulnerable_population(
    'Hillview',
    25,
    22,
    8
).

vulnerable_population(
    'Westend',
    6,
    8,
    2
).

vulnerable_population(
    'Greenfield',
    18,
    15,
    6
).

vulnerable_population(
    'Oldtown',
    4,
    7,
    2
).

% MEDICAL CASES
medical_cases('Riverside', 2, 5, 8).
medical_cases('Downtown', 1, 3, 5).
medical_cases('Midtown', 12, 25, 30).
medical_cases('Northside', 6, 12, 18).
medical_cases('Lakeside', 8, 18, 25).
medical_cases('Eastwood', 3, 7, 12).
medical_cases('Hillview', 10, 20, 25).
medical_cases('Westend', 1, 3, 6).
medical_cases('Greenfield', 7, 15, 20).
medical_cases('Oldtown', 1, 2, 5).

% HOSPITALS
hospital_state(
    'Midtown General Hospital',
    'Midtown',
    300,
    120,
    operational,
    trauma
).

hospital_state(
    'Northside Medical Center',
    'Northside',
    220,
    90,
    operational,
    advanced
).

hospital_state(
    'Hillview Emergency Hospital',
    'Hillview',
    250,
    60,
    limited,
    trauma
).

hospital_state(
    'Central City Hospital',
    'Downtown',
    400,
    210,
    operational,
    advanced
).

hospital_state(
    'Riverside Community Hospital',
    'Riverside',
    180,
    75,
    operational,
    basic
).

% SHELTERS
shelter_state(
    'Riverside Shelter',
    'Riverside',
    500,
    180,
    operational
).

shelter_state(
    'Central Shelter',
    'Downtown',
    800,
    350,
    operational
).

shelter_state(
    'Lakeside Shelter',
    'Lakeside',
    700,
    420,
    limited
).

shelter_state(
    'Hillview Shelter',
    'Hillview',
    1000,
    400,
    operational
).

shelter_state(
    'Northside Relief Center',
    'Northside',
    600,
    300,
    operational
).

shelter_state(
    'Greenfield Community Shelter',
    'Greenfield',
    750,
    280,
    operational
).

% SHELTER FEATURES
shelter_features(
    'Riverside Shelter',
    no,
    yes,
    yes
).

shelter_features(
    'Central Shelter',
    yes,
    yes,
    yes
).

shelter_features(
    'Lakeside Shelter',
    basic,
    yes,
    yes
).

shelter_features(
    'Hillview Shelter',
    advanced,
    yes,
    yes
).

shelter_features(
    'Northside Relief Center',
    basic,
    yes,
    yes
).

shelter_features(
    'Greenfield Community Shelter',
    no,
    yes,
    yes
).

% AMBULANCES
ambulance_state(
    'Ambulance Alpha',
    'Riverside',
    available,
    advanced,
    4
).

ambulance_state(
    'Ambulance Beta',
    'Downtown',
    available,
    basic,
    4
).

ambulance_state(
    'Ambulance Gamma',
    'Hillview',
    available,
    critical_care,
    2
).

ambulance_state(
    'Ambulance Delta',
    'Westend',
    unavailable,
    basic,
    4
).

ambulance_state(
    'Ambulance Echo',
    'Lakeside',
    available,
    advanced,
    4
).

ambulance_state(
    'Ambulance Foxtrot',
    'Northside',
    maintenance,
    advanced,
    4
).

ambulance_state(
    'Ambulance Golf',
    'Greenfield',
    available,
    basic,
    4
).

% ROAD NETWORK
road_state(
    'Riverside Road',
    'Riverside',
    'Downtown',
    4,
    open,
    low
).

road_state(
    'Central Road',
    'Downtown',
    'Midtown',
    3,
    open,
    medium
).

road_state(
    'North Road',
    'Midtown',
    'Northside',
    4,
    open,
    medium
).

road_state(
    'Lake Road',
    'Northside',
    'Lakeside',
    3,
    blocked,
    high
).

road_state(
    'East Road',
    'Midtown',
    'Eastwood',
    5,
    open,
    medium
).

road_state(
    'Hill Road',
    'Eastwood',
    'Hillview',
    4,
    open,
    medium
).

road_state(
    'West Road',
    'Downtown',
    'Westend',
    5,
    congested,
    medium
).

road_state(
    'Green Road',
    'Westend',
    'Greenfield',
    4,
    open,
    low
).

road_state(
    'Old Road',
    'Greenfield',
    'Oldtown',
    3,
    open,
    low
).

road_state(
    'Lake East Road',
    'Lakeside',
    'Eastwood',
    4,
    open,
    medium
).

road_state(
    'River Lake Road',
    'Riverside',
    'Lakeside',
    7,
    open,
    high
).

road_state(
    'Downtown West Road',
    'Downtown',
    'Westend',
    6,
    open,
    medium
).

road_state(
    'Midtown Hill Road',
    'Midtown',
    'Hillview',
    5,
    open,
    medium
).

road_state(
    'North Hill Road',
    'Northside',
    'Hillview',
    4,
    open,
    medium
).

road_state(
    'Green Hill Road',
    'Greenfield',
    'Hillview',
    6,
    blocked,
    high
).

% ROAD CAPACITY / CONGESTION
road_capacity('Riverside Road', 100).
road_capacity('Central Road', 120).
road_capacity('North Road', 100).
road_capacity('Lake Road', 80).
road_capacity('East Road', 90).
road_capacity('Hill Road', 100).
road_capacity('West Road', 70).
road_capacity('Green Road', 100).
road_capacity('Old Road', 90).
road_capacity('Lake East Road', 80).
road_capacity('River Lake Road', 70).
road_capacity('Downtown West Road', 60).
road_capacity('Midtown Hill Road', 90).
road_capacity('North Hill Road', 80).
road_capacity('Green Hill Road', 60).

% ROAD CONGESTION FACTOR
road_congestion_factor('Riverside Road', 1.0).
road_congestion_factor('Central Road', 1.0).
road_congestion_factor('North Road', 1.0).
road_congestion_factor('Lake Road', 1.0).
road_congestion_factor('East Road', 1.0).
road_congestion_factor('Hill Road', 1.0).
road_congestion_factor('West Road', 1.8).
road_congestion_factor('Green Road', 1.0).
road_congestion_factor('Old Road', 1.0).
road_congestion_factor('Lake East Road', 1.2).
road_congestion_factor('River Lake Road', 1.5).
road_congestion_factor('Downtown West Road', 1.3).
road_congestion_factor('Midtown Hill Road', 1.1).
road_congestion_factor('North Hill Road', 1.1).
road_congestion_factor('Green Hill Road', 1.0).

% ZONE COORDINATES
% Used by A* heuristic.
coordinates('Riverside', 0, 0).
coordinates('Downtown', 1, 0).
coordinates('Midtown', 2, 0).
coordinates('Northside', 3, 0).
coordinates('Lakeside', 3, 1).
coordinates('Eastwood', 3, 2).
coordinates('Hillview', 2, 2).
coordinates('Westend', 1, 1).
coordinates('Greenfield', 0, 1).
coordinates('Oldtown', 0, 2).

% OPERATOR OVERRIDES
% Allows a human emergency operator to override an AI
% recommendation.
% Initially there are no overrides : operator_override('Midtown', ambulance, 'Ambulance Gamma').
% SCENARIO METADATA
scenario_name(
    'AION Flood Emergency - Default Scenario'
).

scenario_version(
    '2.0'
).

scenario_description(
    '10-zone simulated urban flood emergency used for AION decision testing.'
).

% Supported risk levels.
risk_level(low).
risk_level(medium).
risk_level(high).
risk_level(critical).

% Supported operational states.
operational_status(operational).
operational_status(limited).
operational_status(closed).

% Supported road states.
road_status(open).
road_status(blocked).
road_status(congested).
road_status(damaged).

% Supported ambulance states.
ambulance_status(available).
ambulance_status(dispatched).
ambulance_status(en_route).
ambulance_status(arrived).
ambulance_status(maintenance).
ambulance_status(unavailable).

% Supported medical capabilities.
medical_capability(basic).
medical_capability(advanced).
medical_capability(critical_care).
medical_capability(trauma).