import { useEffect, useRef } from "react";

type NavigateDetail = { page?: { url?: string; props?: { trace?: { requestId?: string } } }; type?: string };

export function PageAnnouncer() {
  const headingRef = useRef<HTMLElement | null>(null);
  const liveRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const handler = (event: Event) => {
      const detail = (event as CustomEvent<NavigateDetail>).detail;
      if (!detail || detail.type === "initial" || detail.type === "history") return;
      const next = new URL(detail.page?.url ?? "", window.location.origin);
      const current = new URL(window.location.href);
      if (next.pathname === current.pathname) return;

      requestAnimationFrame(() => {
        const heading = document.querySelector<HTMLElement>("main h1, main [role='heading']");
        if (!heading) return;
        heading.setAttribute("tabindex", "-1");
        heading.focus({ preventScroll: true });
        headingRef.current = heading;
        if (liveRef.current) liveRef.current.textContent = heading.textContent ?? "";
      });
    };

    document.addEventListener("inertia:navigate", handler);
    return () => document.removeEventListener("inertia:navigate", handler);
  }, []);

  return <div ref={liveRef} aria-live="polite" aria-atomic="true" className="sr-only" data-testid="page.announcer" />;
}
