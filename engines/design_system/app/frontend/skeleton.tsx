export function Skeleton({ testId }: { testId: string }) {
  return <div data-testid={testId} aria-hidden="true" className="h-4 w-full animate-pulse rounded bg-muted" />;
}
