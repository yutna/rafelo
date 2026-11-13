import { Head } from "@inertiajs/react";
import { Button } from "@design_system/button";
import { TextField } from "@design_system/text_field";

import type { LayoutName } from "../../lib/layout_name";
import { t } from "../../lib/i18n";
import { pageSchema } from "./new.schema";

export default function SignIn(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);

  return (
    <section className="mx-auto max-w-md px-6 py-24">
      <Head title={t("app:signin.title")} />
      <h1 className="text-3xl font-semibold tracking-tight text-slate-900">{t("app:signin.title")}</h1>
      {page.data.error ? <p role="alert" className="mt-4 text-red-700">{page.data.error}</p> : null}
      <form method="post" action={`/${page.app.locale}/sign_in`} className="mt-8 space-y-4">
        <input type="hidden" name="authenticity_token" value={page.meta.csrfToken} />
        <TextField testId="signin.email" label={t("app:signin.email")} name="email" type="email" isRequired autoComplete="email" />
        <TextField testId="signin.password" label={t("app:signin.password")} name="password" type="password" isRequired autoComplete="current-password" />
        <Button testId="signin.submit" type="submit">{t("app:signin.submit")}</Button>
      </form>
    </section>
  );
}

SignIn.layoutName = "auth" satisfies LayoutName;
