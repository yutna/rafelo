import type { ButtonHTMLAttributes, ReactNode } from "react";

import { tv } from "./internal/tailwind";

const button = tv({
  base: "inline-flex items-center justify-center rounded-card px-4 py-2 font-medium focus-visible:outline-2 focus-visible:outline-offset-2",
  variants: {
    variant: {
      primary: "bg-primary text-white hover:bg-primary-hover",
      secondary: "bg-muted text-slate-900 hover:bg-slate-200",
      danger: "bg-danger text-white hover:bg-rose-700",
    },
  },
  defaultVariants: { variant: "primary" },
});

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  testId: string;
  variant?: "primary" | "secondary" | "danger";
  children: ReactNode;
};

export function Button({ testId, variant, className, children, ...props }: ButtonProps) {
  return (
    <button data-testid={testId} className={button({ variant, className })} {...props}>
      {children}
    </button>
  );
}
