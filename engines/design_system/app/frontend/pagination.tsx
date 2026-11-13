type PaginationProps = {
  testId: string;
  page: number;
  perPage: number;
  total: number;
  onPageChange: (page: number) => void;
  label: string;
  previousLabel: string;
  nextLabel: string;
};

export function Pagination({ testId, page, perPage, total, onPageChange, label, previousLabel, nextLabel }: PaginationProps) {
  const pages = Math.max(1, Math.ceil(total / perPage));
  return (
    <nav data-testid={testId} aria-label={label} className="flex items-center gap-2">
      <button type="button" onClick={() => onPageChange(page - 1)} disabled={page <= 1} className="rounded-card bg-muted px-3 py-1">
        {previousLabel}
      </button>
      <span>{page} / {pages}</span>
      <button type="button" onClick={() => onPageChange(page + 1)} disabled={page >= pages} className="rounded-card bg-muted px-3 py-1">
        {nextLabel}
      </button>
    </nav>
  );
}
