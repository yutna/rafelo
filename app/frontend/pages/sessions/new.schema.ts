import { appPathSchema } from "@core/contracts/app_path.schema";
import { definePage } from "@core/contracts/page_props.schema";
import { z } from "zod";

export const pageSchema = definePage({
  data: z.object({ error: z.string().nullable(), formHref: appPathSchema }),
  meta: z.object({ csrfToken: z.string() }),
  query: z.object({}),
  can: [] as const,
  paginated: false,
});
