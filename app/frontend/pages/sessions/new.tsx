import { Button } from "@design_system/button";
import { focusFirstError } from "@design_system/focus_first_error";
import { TextField } from "@design_system/text_field";
import { Head, useForm } from "@inertiajs/react";
import { useEffect, useRef } from "react";

import type { LayoutName } from "@/lib/layout_name";

import { t } from "@/lib/i18n";

import { pageSchema } from "./new.schema";

export default function SignIn(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);
  const form = useForm({ email: "", password: "" });
  const formRef = useRef<HTMLFormElement>(null);
  const formErrors: Record<string, string> = form.errors;
  const baseError = formErrors.base ?? page.data.error;

  useEffect(() => {
    if (baseError) focusFirstError(formRef.current ?? undefined);
  }, [baseError]);

  return (
    <section className="mx-auto max-w-md px-6 py-24">
      <Head title={t("app:signin.title")} />
      <h1 className="text-3xl font-semibold tracking-tight text-slate-900">
        {t("app:signin.title")}
      </h1>
      <form
        ref={formRef}
        onSubmit={(event) => {
          event.preventDefault();
          form.post(page.app.signInHref, {
            onError: () => setTimeout(() => focusFirstError(formRef.current ?? undefined), 0),
          });
        }}
        className="mt-8 space-y-4"
      >
        {baseError ? (
          <p
            role="alert"
            data-testid="signin.error"
            data-error-summary
            tabIndex={-1}
            className="text-red-700"
          >
            {baseError}
          </p>
        ) : null}
        <TextField
          testId="signin.email"
          label={t("app:signin.email")}
          name="email"
          type="email"
          value={form.data.email}
          onChange={(value) => form.setData("email", value)}
          error={formErrors.email}
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
          error={formErrors.password}
          isRequired
          autoComplete="current-password"
        />
        <Button testId="signin.submit" type="submit" isPending={form.processing}>
          {t("app:signin.submit")}
        </Button>
      </form>
    </section>
  );
}

SignIn.layoutName = "auth" satisfies LayoutName;
