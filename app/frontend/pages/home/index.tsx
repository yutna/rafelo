import { Head } from "@inertiajs/react";

import { PageHeading } from "../../components/page_heading";
import { appMetadata } from "../../lib/app_metadata";

type HomeIndexProps = {
  message: string;
};

export default function HomeIndex({ message }: HomeIndexProps) {
  return (
    <main className="mx-auto max-w-2xl px-6 py-24">
      <Head title="Rafelo" />
      <PageHeading
        eyebrow={appMetadata.tagline}
        title={message}
        description="Rails serves the page, Inertia carries the props, and React renders it."
      />
    </main>
  );
}
