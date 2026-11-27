export default [
  {
    ignores: ["**/ignored*.ts"],
  },
  {
    files: ["**/*.{ts,tsx}"],
    rules: {},
  },
  {
    files: ["engines/aaa/zzz/**/*.{ts,tsx}"],
    languageOptions: { parserOptions: { project: true } },
  },
];
