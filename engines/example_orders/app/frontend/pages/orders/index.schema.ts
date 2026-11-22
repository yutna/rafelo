import { chartSchema, definePage, moneySchema } from "@core/contracts/page_props.schema";
import { hrefSchema } from "@design_system/safe_url";
import { z } from "zod";

const orderSchema = z.object({
  id: z.string(),
  number: z.string(),
  customer: z.object({ id: z.string(), name: z.string(), tier: z.string() }),
  status: z.string(),
  total: moneySchema,
  issuedOn: z.string(),
  href: hrefSchema,
});

export const pageSchema = definePage({
  data: z.object({
    items: z.array(orderSchema),
    newHref: hrefSchema.nullable(),
    exportHref: hrefSchema,
    filterHrefs: z.array(
      z.object({ key: z.string(), label: z.string(), href: hrefSchema, current: z.boolean() }),
    ),
    previousHref: hrefSchema.nullable(),
    nextHref: hrefSchema.nullable(),
    chart: chartSchema.optional(),
  }),
  meta: z.object({ formToken: z.string() }),
  query: z.object({
    page: z.number().int(),
    perPage: z.number().int(),
    sort: z.string().nullable(),
    direction: z.string(),
    filters: z.record(z.string(), z.string()),
    cursor: z.string().nullable(),
  }),
  can: ["order.create", "order.export"] as const,
});
