import { Button } from "@design_system/button";
import { TextField } from "@design_system/text_field";
import { Head, useForm } from "@inertiajs/react";

import type { LayoutName } from "@/lib/layout_name";

import { t } from "@/lib/i18n";

import { pageSchema } from "./new.schema";

export default function SignIn(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);
  const form = useForm({ email: "", password: "" });

  return (
    <section className="mx-auto max-w-md px-6 py-24">
      <Head title={t("app:signin.title")} />
      <h1 className="text-3xl font-semibold tracking-tight text-slate-900">
        {t("app:signin.title")}
      </h1>
      {page.data.error ? (
        <p role="alert" className="mt-4 text-red-700">
          {page.data.error}
        </p>
      ) : null}
      <form
        onSubmit={(event) => {
          event.preventDefault();
          form.post(page.app.signInHref);
        }}
        className="mt-8 space-y-4"
      >
        <TextField
          testId="signin.email"
          label={t("app:signin.email")}
          name="email"
          type="email"
          value={form.data.email}
          onChange={(value) => form.setData("email", value)}
          isRequired
          autoComplete="email"
        />
        <TextField
          testId="signin.password"
          label={t("app:signin.password")}
          name="password"
          type="password"
          value={form.data.password}
          onChange={(value) => form.setData("password", value)}
          isRequired
          autoComplete="current-password"
        />
        <Button testId="signin.submit" type="submit" isDisabled={form.processing}>
          {t("app:signin.submit")}
        </Button>
      </form>
    </section>
  );
}

SignIn.layoutName = "auth" satisfies LayoutName;
