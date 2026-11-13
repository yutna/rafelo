import { extendTailwindMerge } from "tailwind-merge";
import { createTV } from "tailwind-variants/lite";

export const twMerge = extendTailwindMerge({
  extend: {
    theme: {
      text: [ "display" ],
      shadow: [ "card" ],
      radius: [ "card" ],
    },
  },
});

export const tv = createTV({ twMerge });
