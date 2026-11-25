import { Head } from "@inertiajs/react";

import type { LayoutName } from "@/lib/layout_name";

import { t } from "@/lib/i18n";
import { SignInScreen } from "@/screens/sessions/sign_in_screen";

import { pageSchema } from "./new.schema";

export default function SignIn(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);

  return (
    <>
      <Head title={t("app:signin.title")} />
      <SignInScreen signInHref={page.data.formHref} error={page.data.error} />
    </>
  );
}

SignIn.layoutName = "auth" satisfies LayoutName;
