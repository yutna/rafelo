import { Deferred, Link } from "@inertiajs/react";

export function Widget() {
  return (
    <Deferred data="orders">
      <Link href="/orders">Orders</Link>
    </Deferred>
  );
}
