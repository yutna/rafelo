import { router } from "@inertiajs/react";

export function useOrderExport() {
  return (href: string, token: string) => router.post(href, { token });
}
