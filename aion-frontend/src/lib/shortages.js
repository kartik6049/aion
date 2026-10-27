// A shortage means that, after higher-priority zones were served, nothing
// suitable remained for this zone.
const DESCRIPTIONS = {
  hospital: 'No hospital with enough free beds could be assigned',
  shelter: 'No shelter with enough space could be assigned',
  ambulance: 'No suitable ambulance was left to assign',
}

export function describeShortage(type) {
  return DESCRIPTIONS[type] ?? 'Resource shortage'
}
