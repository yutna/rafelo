import { PageHeading } from "../../components/page_heading";
import { appMetadata } from "../../lib/app_metadata";

type HomeScreenProps = {
  message: string;
};

export function HomeScreen({ message }: HomeScreenProps) {
  return (
    <main className="mx-auto max-w-2xl px-6 py-24">
      <PageHeading
        eyebrow={appMetadata.tagline}
        title={message}
        description="Rails serves the page, Inertia carries the props, and React renders it."
      />
    </main>
  );
}
