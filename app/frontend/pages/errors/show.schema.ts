import { definePage } from "@core/contracts/page_props.schema";
import { z } from "zod";

export const pageSchema = definePage({
  data: z.object({
    code: z.string(),
    message: z.string(),
    requestId: z.string(),
    traceId: z.string(),
    retryable: z.boolean(),
  }),
  query: z.object({}),
  can: [] as const,
  paginated: false,
});
