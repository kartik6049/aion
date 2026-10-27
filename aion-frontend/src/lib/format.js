/** "immediate_evacuation" -> "Immediate Evacuation"; empty values -> fallback. */
export function formatText(value, fallback = 'Unknown') {
  if (value === null || value === undefined || value === '') return fallback

  return String(value)
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase())
}
