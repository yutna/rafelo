import { usePage } from "@inertiajs/react";
import { useEffect, useRef } from "react";

export function PageAnnouncer() {
  const page = usePage();
  const lastUrl = useRef<string | null>(null);
  const live = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (lastUrl.current === page.url) return;
    lastUrl.current = page.url;
    const heading = document.querySelector<HTMLElement>("main h1, main [role='heading']");
    heading?.setAttribute("tabindex", "-1");
    heading?.focus();
    if (live.current) {
      live.current.textContent = document.title;
    }
  }, [page.url]);

  return <div ref={live} aria-live="polite" aria-atomic="true" className="sr-only" data-testid="page-announcer" />;
}
