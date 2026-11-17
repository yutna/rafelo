// Local ESLint rules (TS-05). The TS-07 meta-check lists these names and
// requires a canary for each.
const SKIP_FORMS = [
  /(?<![\w.:])skip(?![\w:])/,
  /\b(?:xit|xspecify|xexample|xdescribe|xcontext)\b/,
  /\.skip\b/,
  /\bpending(?!\s*:)/,
  /\b(?:skip|pending):/,
  /\bprosopite:\s*false\b/,
  /\bProsopite\.pause\b/,
  /\b(?:it|test|describe)\.(?:todo|skipIf|fixme)\b/,
  /\btest\.describe\.(?:skip|fixme)\b/,
];
const ISSUE_REFERENCE = /(?:#\d+|https:\/\/github\.com\/[^/\s]+\/[^/\s]+\/issues\/\d+)/;

const skipNeedsIssue = {
  meta: {
    type: "problem",
    docs: { description: "A skipped test carries an issue reference on its line (TS-05)." },
    schema: [],
    messages: {
      missing:
        "A skip needs an issue reference (#<number> or an issue URL) on the same line (TS-05).",
    },
  },
  create(context) {
    return {
      Program() {
        const source = context.sourceCode ?? context.getSourceCode();
        source.lines.forEach((line, index) => {
          const code = line.split(/\s+#\s*/, 2)[0] ?? "";
          if (code.trimStart().startsWith("#") || code.trimStart().startsWith("//")) return;
          if (!SKIP_FORMS.some((form) => form.test(code))) return;
          if (ISSUE_REFERENCE.test(line)) return;
          context.report({
            loc: { line: index + 1, column: 0 },
            messageId: "missing",
          });
        });
      },
    };
  },
};

export default {
  meta: { name: "rafelo" },
  rules: { "skip-needs-issue": skipNeedsIssue },
};
