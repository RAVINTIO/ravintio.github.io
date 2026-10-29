// initiative-labels.mjs - telemetry labels for initiative steps (0000151 ADR-005).
//
// Exports:
//   encodeLabelValue(value)            Percent-encodes comma, equals, space, and percent.
//   withInitiativeLabels(old, id, slug, position)
//                                      Returns OTEL_RESOURCE_ATTRIBUTES with the three
//                                      initiative labels appended to the old value.
//
// The labels hold identifiers only. It has no dependencies.

// Encodes percent first so the function never encodes its own output twice.
export function encodeLabelValue(value) {
  return String(value)
    .replace(/%/g, '%25')
    .replace(/,/g, '%2C')
    .replace(/=/g, '%3D')
    .replace(/ /g, '%20');
}

// Keeps the old value byte for byte and adds no second comma after a trailing comma.
export function withInitiativeLabels(old, id, slug, position) {
  const labels = [
    'work.kind=initiative',
    `ravintio.initiative=${encodeLabelValue(`${id}-${slug}`)}`,
    `ravintio.step=${encodeLabelValue(position)}`,
  ].join(',');
  if (!old) return labels;
  return old.endsWith(',') ? `${old}${labels}` : `${old},${labels}`;
}
