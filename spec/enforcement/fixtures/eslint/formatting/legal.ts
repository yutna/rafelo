const now = new Date();
const amount = 12.345;

export const formatted = new Intl.DateTimeFormat("en").format(now);
export const money = amount.toFixed(2);
