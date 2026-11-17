import { usePage } from "@inertiajs/react";

export function Layout() {
  const page = usePage();
  return <main>{page.component}</main>;
}
