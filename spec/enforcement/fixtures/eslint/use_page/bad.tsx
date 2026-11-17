import * as Inertia from "@inertiajs/react";
import { usePage as readPage } from "@inertiajs/react";

export function Widget() {
  readPage();
  Inertia.usePage();
  return null;
}
