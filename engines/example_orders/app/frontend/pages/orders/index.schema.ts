import { z } from "zod";

import { definePage } from "@core/contracts/page_props.schema";

const orderSchema = z.object({
  id: z.string(),
  number: z.string(),
  customer: z.object({ id: z.string(), name: z.string(), tier: z.string() }),
  status: z.string(),
  total: z.object({ minor: z.int(), currency: z.string().length(3), exponent: z.int() }),
  issuedOn: z.string(),
  href: z.string(),
});

export const pageSchema = definePage({
  data: z.object({
    items: z.array(orderSchema),
    newHref: z.string().nullable(),
    exportPath: z.string(),
    filterHrefs: z.array(z.object({ label: z.string(), href: z.string(), current: z.boolean() })),
    previousHref: z.string().nullable(),
    nextHref: z.string().nullable(),
    chart: z.object({ series: z.array(z.record(z.string(), z.unknown())) }).optional(),
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
