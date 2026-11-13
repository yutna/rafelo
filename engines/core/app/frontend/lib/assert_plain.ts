export function assertPlain(value: unknown, path = "state", seen = new WeakSet<object>()): void {
  if (value === null || value === undefined) return;

  const type = typeof value;
  if (type === "string" || type === "number" || type === "boolean" || type === "bigint") return;
  if (type !== "object") throw new TypeError(`${path} is a ${type}, not plain data (OOP-05)`);

  if (seen.has(value)) return;
  seen.add(value);

  const prototype: unknown = Object.getPrototypeOf(value);
  const isArray = Array.isArray(value) && prototype === Array.prototype;
  if (!isArray && prototype !== Object.prototype && prototype !== null) {
    const name = (prototype as { constructor?: { name?: string } }).constructor?.name ?? "object";
    throw new TypeError(`${path} is a ${name}, not plain data (OOP-05)`);
  }
  if (Object.getOwnPropertySymbols(value).length > 0) {
    throw new TypeError(`${path} has a symbol key, not plain data (OOP-05)`);
  }

  for (const [key, child] of Object.entries(value)) {
    assertPlain(child, isArray ? `${path}[${key}]` : `${path}.${key}`, seen);
  }
}
