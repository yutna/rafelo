import { PageHeading } from "../../components/page_heading";
import { t } from "../../lib/i18n";

type HomeScreenProps = {
  message: string;
};

export function HomeScreen({ message }: HomeScreenProps) {
  return (
    <main className="mx-auto max-w-2xl px-6 py-24">
      <PageHeading
        eyebrow={t("app:home.tagline")}
        title={message}
        description={t("app:home.description")}
      />
    </main>
  );
}
