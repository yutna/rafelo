import { definePage } from "@core/contracts/page_props.schema";
import { hrefSchema } from "@design_system/safe_url";
import { z } from "zod";

export const pageSchema = definePage({
  data: z.object({
    order: z.object({
      id: z.string(),
      number: z.string(),
      customerName: z.string(),
      status: z.string(),
      version: z.int(),
    }),
    updateHref: hrefSchema,
    showHref: hrefSchema,
  }),
  meta: z.object({ formToken: z.string() }),
  query: z.object({}),
  can: [] as const,
  paginated: false,
});
