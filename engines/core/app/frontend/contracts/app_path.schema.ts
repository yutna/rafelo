import { z } from "zod";

export const appPathSchema = z.string().refine(
  (value) =>
    value === value.trim() &&
    value.startsWith("/") &&
    !value.startsWith("//") &&
    !/[\\\u0000-\u001f\u007f]/.test(value),
  "must be a safe app-relative path",
);
