type CustomerBadgeProps = {
  name: string;
  tier: string;
  testId?: string;
};

export function CustomerBadge({ name, tier, testId = "example_customers.badge" }: CustomerBadgeProps) {
  return (
    <span data-testid={testId} className="inline-flex items-center gap-2 rounded-card bg-muted px-2 py-1 text-sm">
      <span className="font-medium">{name}</span>
      <span className="text-muted-foreground">{tier}</span>
    </span>
  );
}
