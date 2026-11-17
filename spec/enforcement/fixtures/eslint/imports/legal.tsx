import type { PageProps } from "@core/contracts/page_props.schema";

import { Link } from "@inertiajs/react";

export function Widget({ page }: { page: PageProps }) {
  return <Link href={page.url}>{page.component}</Link>;
}
