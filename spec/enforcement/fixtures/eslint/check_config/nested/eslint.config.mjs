export default [
  {
    files: ["**/*.{ts,tsx}"],
    rules: {},
  },
  {
    files: ["app/frontend/legacy/**"],
    languageOptions: { parserOptions: { project: true } },
  },
];
