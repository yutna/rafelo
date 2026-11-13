import { z } from "zod";

import { definePage } from "@core/contracts/page_props.schema";

export const pageSchema = definePage({
  data: z.object({}),
  query: z.object({}),
  can: [] as const,
  paginated: false,
});
