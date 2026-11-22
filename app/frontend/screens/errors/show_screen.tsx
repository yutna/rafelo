type Props = {
  code: string;
  message: string;
  requestId: string;
  traceId: string;
  retryable: boolean;
};

export function ErrorShowScreen({ code, message, requestId, traceId }: Props) {
  return (
    <section className="mx-auto max-w-2xl px-6 py-24">
      <p
        className="text-sm font-medium tracking-wider text-slate-500 uppercase"
        data-testid="errors.code"
      >
        {code}
      </p>
      <h1 className="mt-4 text-3xl font-semibold text-slate-900" data-testid="errors.message">
        {message}
      </h1>
      <p className="mt-4 text-sm text-slate-600" data-testid="errors.trace">
        {requestId} · {traceId}
      </p>
    </section>
  );
}
