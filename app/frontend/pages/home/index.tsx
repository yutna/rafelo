import { Head } from "@inertiajs/react";

type HomeIndexProps = {
  message: string;
};

export default function HomeIndex({ message }: HomeIndexProps) {
  return (
    <main className="mx-auto max-w-2xl px-6 py-24">
      <Head title="Rafelo" />
      <p className="text-sm font-medium uppercase tracking-wider text-slate-500">
        Rails BFF template
      </p>
      <h1 className="mt-4 text-4xl font-semibold tracking-tight text-slate-900">
        {message}
      </h1>
      <p className="mt-4 text-lg leading-relaxed text-slate-600">
        Rails serves the page, Inertia carries the props, and React renders it.
      </p>
    </main>
  );
}
