import { Head } from "@inertiajs/react";

import type { LayoutName } from "@/lib/layout_name";

import { HomeScreen } from "@/screens/home/home_screen";

import { pageSchema } from "./index.schema";

export default function HomeIndex(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);

  return (
    <>
      <Head title="Rafelo" />
      <HomeScreen message={page.data.message} />
    </>
  );
}

HomeIndex.layoutName = "app" satisfies LayoutName;
