import { definePage, moneySchema } from "@core/contracts/page_props.schema";
import { z } from "zod";

export const pageSchema = definePage({
  data: z.object({
    order: z.object({
      id: z.string(),
      number: z.string(),
      customer: z.object({ id: z.string(), name: z.string(), tier: z.string() }),
      status: z.string(),
      total: moneySchema,
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
