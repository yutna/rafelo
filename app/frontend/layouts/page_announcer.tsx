import { useEffect, useRef } from "react";

type NavigateDetail = { page?: { url?: string }; type?: string };

export function PageAnnouncer() {
  const liveRef = useRef<HTMLDivElement | null>(null);
  const pathRef = useRef<string>(typeof window === "undefined" ? "" : window.location.pathname);

  useEffect(() => {
    const handler = (event: Event) => {
      const detail = (event as CustomEvent<NavigateDetail>).detail;
      if (!detail || detail.type === "initial") return;

      const next = new URL(detail.page?.url ?? "", window.location.origin).pathname;
      const previous = pathRef.current;
      pathRef.current = next;
      if (next === previous) return;

      requestAnimationFrame(() => {
        const heading = document.querySelector<HTMLElement>("main h1, main [role='heading']");
        if (!heading) {
          if (liveRef.current) liveRef.current.textContent = document.title;
          return;
        }
        heading.setAttribute("tabindex", "-1");
        heading.focus({ preventScroll: true });
        if (liveRef.current) liveRef.current.textContent = heading.textContent ?? "";
      });
    };

    document.addEventListener("inertia:navigate", handler);
    return () => document.removeEventListener("inertia:navigate", handler);
  }, []);

  return <div ref={liveRef} aria-live="polite" aria-atomic="true" className="sr-only" data-testid="page.announcer" />;
}
