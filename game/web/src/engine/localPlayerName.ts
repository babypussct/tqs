/** With TQS2, the native server owns the name for every player, including
 * reconnects to an existing match. TQS1 needs a browser-only fallback. */
export function localNameOverrideForTicket(ticket: string, displayName: string): string | undefined {
  return ticket.startsWith('TQS2|') ? undefined : displayName;
}

/** Only the authenticated local player's public seat label is overridden.
 * Numeric IDs, native account names and server-owned opponent names remain intact. */
export function localPlayerDisplayEvent(command: string, data: unknown,
  ownId: number | null, displayName: string | undefined): unknown {
  const name = displayName?.trim();
  if (!name || !Number.isSafeInteger(ownId) || ownId === null || ownId <= 0) return data;
  if ((command === 'AddPlayer' || command === 'AddObserver') && Array.isArray(data) && data[0] === ownId) {
    return [data[0], name, ...data.slice(2)];
  }
  if (command !== 'EnterRoom' || !Array.isArray(data) || data.length < 3 ||
      !data[2] || typeof data[2] !== 'object' || Array.isArray(data[2])) return data;
  const settings = data[2] as Record<string, unknown>;
  const rewrite = (people: unknown): unknown => Array.isArray(people)
    ? people.map((person) => Array.isArray(person) && person[0] === ownId
      ? [person[0], name, ...person.slice(2)] : person)
    : people;
  return [data[0], data[1], { ...settings,
    _players: rewrite(settings._players), _observers: rewrite(settings._observers) }, ...data.slice(3)];
}
