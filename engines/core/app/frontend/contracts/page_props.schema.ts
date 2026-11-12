import { z } from "zod";

import { appPathSchema } from "./app_path.schema";
import { localeSchema } from "./locales.generated";

export const capabilitySchema = z.strictObject({
  allowed: z.boolean(),
  reason: z.string().nullable(),
});

export const moneySchema = z.object({
  minor: z.int(),
  currency: z.string().length(3),
  exponent: z.int().min(0).max(4),
});

export const paginationSchema = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("offset"),
    page: z.number().int().min(1),
    perPage: z.number().int().min(1),
    total: z.number().int().min(0),
    pageCount: z.number().int().min(0),
  }),
  z.object({
    kind: z.literal("cursor"),
    perPage: z.number().int().min(1),
    next: z.string().nullable(),
    prev: z.string().nullable(),
  }),
]);

export const flashSchema = z.strictObject({
  notice: z.string().min(1).optional(),
  alert: z.string().min(1).optional(),
});

export const sharedPropsSchema = z.object({
  auth: z.object({ viewer: z.object({ id: z.string(), name: z.string() }).nullable() }),
  trace: z.object({ requestId: z.string(), traceId: z.string() }),
  app: z.object({
    name: z.string(),
    locale: localeSchema,
    locales: z.array(localeSchema),
    localeHrefs: z.array(z.object({ locale: localeSchema, href: appPathSchema })),
    timeZone: z.string(),
  }),
  nav: z.array(
    z.object({
      key: z.string(),
      label: z.string(),
      path: appPathSchema,
      icon: z.string(),
      current: z.boolean(),
    }),
  ),
  errors: z.record(z.string(), z.string()),
});

const emptyMeta = z.strictObject({});

function canSchema<const K extends readonly string[]>(keys: K) {
  const shape = Object.fromEntries(keys.map((key) => [key, capabilitySchema]));
  return z.strictObject(shape as Record<K[number], typeof capabilitySchema>);
}

type PaginationFor<P extends boolean> = P extends false ? z.ZodNull : z.ZodNullable<typeof paginationSchema>;

export function definePage<
  D extends z.ZodType,
  Q extends z.ZodType,
  const C extends readonly string[],
  M extends z.ZodType = typeof emptyMeta,
  P extends boolean = true,
>(parts: { data: D; query: Q; can: C; meta?: M; paginated?: P }) {
  const pagination = parts.paginated === false ? z.null() : paginationSchema.nullable();
  return z.object({
    ...sharedPropsSchema.shape,
    data: parts.data,
    meta: (parts.meta ?? emptyMeta) as M,
    query: parts.query,
    pagination: pagination as PaginationFor<P>,
    can: canSchema(parts.can),
  });
}
