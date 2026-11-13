import { z } from "zod";

import { definePage } from "@core/contracts/page_props.schema";

export const pageSchema = definePage({
  data: z.object({ createPath: z.string(), indexPath: z.string() }),
  meta: z.object({ formToken: z.string() }),
  query: z.object({}),
  can: [] as const,
  paginated: false,
});
