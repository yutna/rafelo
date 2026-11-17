import { useState } from "react";
import { usePage } from "@inertiajs/react";
import { Orders } from "@engines/example_orders/public";
import { Button as AriaButton } from "react-aria-components";
import { CalendarDate } from "@internationalized/date";
import { tv } from "tailwind-variants";
import { twMerge } from "tailwind-merge";
import { init } from "echarts";
import { createColumnHelper } from "@tanstack/react-table";
import { Bell } from "lucide-react";
import { Link } from "react-router-dom";
import { helper } from "../helper";

export function Widget() {
  const [value] = useState(0);
  usePage();
  return (
    <div>
      {String(Orders)}
      {String(AriaButton)}
      {String(CalendarDate)}
      {String(tv)}
      {String(twMerge)}
      {String(init)}
      {String(createColumnHelper)}
      {String(Bell)}
      {String(helper)}
      <Link to="/orders">{value}</Link>
    </div>
  );
}
