import { z } from "zod";

import { definePage } from "@core/contracts/page_props.schema";

export const pageSchema = definePage({
  data: z.object({
    order: z.object({
      id: z.string(),
      number: z.string(),
      customerName: z.string(),
      status: z.string(),
      version: z.int(),
    }),
    updatePath: z.string(),
    showPath: z.string(),
  }),
  meta: z.object({ formToken: z.string() }),
  query: z.object({}),
  can: [] as const,
  paginated: false,
});
