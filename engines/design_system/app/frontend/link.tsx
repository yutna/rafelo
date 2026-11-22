import type { ReactNode } from "react";

import { Link as InertiaLink } from "@inertiajs/react";

import type { Href } from "./safe_url";

import { isAppPath, isSafeUrl } from "./safe_url";

type LinkProps = {
  testId: string;
  href: Href;
  children: ReactNode;
  className?: string;
};

export function Link({ testId, href, children, className }: LinkProps) {
  if (!isSafeUrl(href)) {
    return (
      <span data-testid={testId} className={className}>
        {children}
      </span>
    );
  }

  if (!isAppPath(href)) {
    return (
      <a data-testid={testId} href={href} className={className}>
        {children}
      </a>
    );
  }

  return (
    <InertiaLink data-testid={testId} href={href} className={className}>
      {children}
    </InertiaLink>
  );
}
