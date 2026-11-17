import { createInertiaApp } from "@inertiajs/core";
import Inertia, { router, useForm, usePage, WhenVisible } from "@inertiajs/react";

export function Widget() {
  router.visit("/");
  useForm({});
  usePage();
  return (
    <div>
      {String(WhenVisible)}
      {String(Inertia)}
      {String(createInertiaApp)}
    </div>
  );
}
