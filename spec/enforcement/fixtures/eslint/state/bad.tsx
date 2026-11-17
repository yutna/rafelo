import * as React from "react";

import { useOptimistic, useState } from "react";

export function Widget() {
  const [count] = useState(0);
  const [reduced] = React.useReducer((value: number) => value, 0);
  const [action] = React.useActionState(async () => "saved", "idle");
  const [optimistic] = useOptimistic(count);
  const [state] = React.useState(0);
  return <div>{`${reduced}${action}${optimistic}${state}${count}`}</div>;
}
