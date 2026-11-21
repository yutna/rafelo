import type { ReactNode } from "react";

import { TextField } from "./text_field";

type FilterBarProps = {
  testId: string;
  label: string;
  searchLabel: string;
  searchValue: string;
  onSearchChange: (value: string) => void;
  children?: ReactNode;
};

export function FilterBar({
  testId,
  label,
  searchLabel,
  searchValue,
  onSearchChange,
  children,
}: FilterBarProps) {
  return (
    <div
      role="search"
      aria-label={label}
      data-testid={testId}
      className="flex flex-wrap items-end gap-3 rounded-card border border-slate-200 bg-surface p-3"
    >
      <TextField
        testId={`${testId}.search`}
        label={searchLabel}
        value={searchValue}
        onChange={onSearchChange}
      />
      {children}
    </div>
  );
}
