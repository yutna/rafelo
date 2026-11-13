import { Head } from "@inertiajs/react";

import { pageSchema } from "./new.schema";

export default function SignIn(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);

  return (
    <main className="mx-auto max-w-md px-6 py-24">
      <Head title="Sign in" />
      <h1 className="text-3xl font-semibold tracking-tight text-slate-900">Sign in</h1>
      {page.data.error ? <p role="alert" className="mt-4 text-red-700">{page.data.error}</p> : null}
      <form method="post" action={`/${page.app.locale}/sign_in`} className="mt-8 space-y-4">
        <input type="hidden" name="authenticity_token" value={page.meta.csrfToken} />
        <label className="block text-sm font-medium text-slate-700">
          Email
          <input name="email" type="email" required className="mt-1 w-full rounded border px-3 py-2" />
        </label>
        <label className="block text-sm font-medium text-slate-700">
          Password
          <input name="password" type="password" required className="mt-1 w-full rounded border px-3 py-2" />
        </label>
        <button type="submit" className="rounded bg-slate-900 px-4 py-2 text-white">Sign in</button>
      </form>
    </main>
  );
}
