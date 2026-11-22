import { extendTailwindMerge } from "tailwind-merge";
import { createTV } from "tailwind-variants/lite";

export const themeTokens: Record<"text" | "shadow" | "radius", string[]> = {
  text: ["display"],
  shadow: ["card"],
  radius: ["card"],
};

export const twMerge = extendTailwindMerge({
  extend: {
    theme: themeTokens,
  },
});

export const tv = createTV({ twMerge });
