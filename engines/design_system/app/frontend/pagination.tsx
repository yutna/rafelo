import { Button as AriaButton } from "react-aria-components";

import { t } from "./i18n";

type CommonProps = {
  testId: string;
  label: string;
  previousLabel: string;
  nextLabel: string;
};

type OffsetPaginationProps = CommonProps & {
  kind?: "offset";
  page: number;
  perPage: number;
  total: number;
  onPageChange: (page: number) => void;
};

type CursorPaginationProps = CommonProps & {
  kind: "cursor";
  previousHref: string | null;
  nextHref: string | null;
  onNavigate: (href: string) => void;
  status: string;
};

type PaginationProps = OffsetPaginationProps | CursorPaginationProps;

export function Pagination(props: PaginationProps) {
  const { testId, label, previousLabel, nextLabel } = props;

  if (props.kind === "cursor") {
    return (
      <nav data-testid={testId} aria-label={label} className="flex items-center gap-2">
        <AriaButton
          data-testid={`${testId}.previous`}
          aria-disabled={props.previousHref === null}
          onPress={() => {
            if (props.previousHref) props.onNavigate(props.previousHref);
          }}
          className="rounded-card bg-muted px-3 py-1 aria-disabled:opacity-50"
        >
          {previousLabel}
        </AriaButton>
        <p role="status" aria-live="polite" data-testid={`${testId}.status`}>
          {props.status}
        </p>
        <AriaButton
          data-testid={`${testId}.next`}
          aria-disabled={props.nextHref === null}
          onPress={() => {
            if (props.nextHref) props.onNavigate(props.nextHref);
          }}
          className="rounded-card bg-muted px-3 py-1 aria-disabled:opacity-50"
        >
          {nextLabel}
        </AriaButton>
      </nav>
    );
  }

  const pages = Math.max(1, Math.ceil(props.total / props.perPage));
  const atStart = props.page <= 1;
  const atEnd = props.page >= pages;

  return (
    <nav data-testid={testId} aria-label={label} className="flex items-center gap-2">
      <AriaButton
        data-testid={`${testId}.previous`}
        aria-disabled={atStart}
        onPress={() => {
          if (!atStart) props.onPageChange(props.page - 1);
        }}
        className="rounded-card bg-muted px-3 py-1 aria-disabled:opacity-50"
      >
        {previousLabel}
      </AriaButton>
      <p role="status" aria-live="polite" data-testid={`${testId}.status`}>
        {t("pagination.page_of", { page: props.page, pages })}
      </p>
      <AriaButton
        data-testid={`${testId}.next`}
        aria-disabled={atEnd}
        onPress={() => {
          if (!atEnd) props.onPageChange(props.page + 1);
        }}
        className="rounded-card bg-muted px-3 py-1 aria-disabled:opacity-50"
      >
        {nextLabel}
      </AriaButton>
    </nav>
  );
}
