import { definePage } from "@core/contracts/page_props.schema";
import { z } from "zod";

export const pageSchema = definePage({
  data: z.object({ message: z.string() }),
  query: z.object({}),
  can: [] as const,
  paginated: false,
});
