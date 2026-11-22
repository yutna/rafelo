export type OrderListRow = {
  id: string;
  number: string;
  customer: { id: string; name: string; tier: string };
  status: string;
  total: { minor: number; currency: string; exponent: number };
  issuedOn: string;
  href: string;
};
