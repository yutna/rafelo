import { z } from "zod";

import { definePage } from "@core/contracts/page_props.schema";

export const pageSchema = definePage({
  data: z.object({ error: z.string().nullable() }),
  meta: z.object({ csrfToken: z.string() }),
  query: z.object({}),
  can: [] as const,
  paginated: false,
});
