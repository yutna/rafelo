import { z } from "zod";

import { definePage } from "@core/contracts/page_props.schema";

export const pageSchema = definePage({
  data: z.object({
    order: z.object({
      id: z.string(),
      number: z.string(),
      customer: z.object({ id: z.string(), name: z.string(), tier: z.string() }),
      status: z.string(),
      total: z.object({ minor: z.int(), currency: z.string().length(3), exponent: z.int() }),
      issuedOn: z.string(),
      version: z.int(),
    }),
    editHref: z.string(),
    indexPath: z.string(),
  }),
  query: z.object({}),
  can: ["order.update"] as const,
  paginated: false,
});
