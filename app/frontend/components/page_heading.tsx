type PageHeadingProps = {
  eyebrow?: string;
  title: string;
  description?: string;
};

export function PageHeading({ eyebrow, title, description }: PageHeadingProps) {
  return (
    <header>
      {eyebrow ? (
        <p className="text-sm font-medium uppercase tracking-wider text-slate-500">
          {eyebrow}
        </p>
      ) : null}
      <h1 className="mt-4 text-4xl font-semibold tracking-tight text-slate-900">
        {title}
      </h1>
      {description ? (
        <p className="mt-4 text-lg leading-relaxed text-slate-600">
          {description}
        </p>
      ) : null}
    </header>
  );
}
