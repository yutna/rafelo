import { z } from "zod";

export const appPathSchema = z.string().regex(/^\/(?!\/)/, "must be an app-relative path");
