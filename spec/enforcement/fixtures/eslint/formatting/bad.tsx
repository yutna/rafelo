const now = new Date();
const amount = 12.345;

const clock = now.toLocaleTimeString("en");
const date = now.toLocaleDateString("en");
const text = now.toLocaleString("en");
const money = amount.toFixed(2);
const formatted = new Intl.DateTimeFormat("en").format(now);
const number = new Intl.NumberFormat("en").format(amount);
const relative = new Intl.RelativeTimeFormat("en").format(-1, "day");

export const values = { clock, date, formatted, money, number, relative, text };
