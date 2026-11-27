export default [
  {
    files: ["**/*.{ts,tsx}"],
    rules: {},
  },
  {
    files: ["**/*.test.tsx"],
    languageOptions: { parserOptions: { project: true } },
  },
];
