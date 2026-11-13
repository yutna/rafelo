export function OrdersList({
  items,
}: {
  items: { id: string; label: string }[];
}) {
  if (items.length === 0) return <p className="mt-4">No orders yet.</p>;
  return (
    <ul
      className="mt-4 space-y-2"
      data-testid="example_orders.orders.index.list"
    >
      {items.map((item) => (
        <li
          key={item.id}
          data-testid={`example_orders.orders.index.row.${item.id}`}
        >
          {item.label}
        </li>
      ))}
    </ul>
  );
}
