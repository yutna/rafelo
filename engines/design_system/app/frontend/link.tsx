import { Link as InertiaLink } from "@inertiajs/react";
import type { ReactNode } from "react";

import { isSafeUrl } from "./safe_url";

type LinkProps = {
  href: string;
  children: ReactNode;
  className?: string;
};

export function Link({ href, children, className }: LinkProps) {
  if (!isSafeUrl(href)) return <span className={className}>{children}</span>;
  return (
    <InertiaLink href={href} className={className}>
      {children}
    </InertiaLink>
  );
}
