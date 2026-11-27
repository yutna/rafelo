export default [
  {
    ignores: ["ignored*.ts"],
  },
  {
    files: ["**/*.{ts,tsx}"],
    languageOptions: { parserOptions: { project: true } },
  },
];
