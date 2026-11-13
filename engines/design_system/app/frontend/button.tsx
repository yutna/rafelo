import type { ReactNode } from "react";
import { Button as AriaButton } from "react-aria-components";

import { tv } from "./internal/tailwind";

const button = tv({
  base: "inline-flex items-center justify-center rounded-card px-4 py-2 font-medium outline-offset-2 focus-visible:outline-2",
  variants: {
    variant: {
      primary: "bg-primary text-white hover:bg-primary-hover",
      secondary: "bg-muted text-slate-900 hover:bg-slate-200",
      danger: "bg-danger text-white hover:bg-rose-700",
    },
  },
  defaultVariants: { variant: "primary" },
});

type ButtonProps = {
  testId: string;
  variant?: "primary" | "secondary" | "danger";
  type?: "button" | "submit" | "reset";
  className?: string;
  onPress?: () => void;
  isDisabled?: boolean;
  children: ReactNode;
};

export function Button({ testId, variant, className, children, ...props }: ButtonProps) {
  return (
    <AriaButton data-testid={testId} className={button({ variant, className })} {...props}>
      {children}
    </AriaButton>
  );
}
