export default [
  {
    files: ["**/*.{ts,tsx}"],
    rules: {},
  },
  {
    files: ["engines/**/*.tsx"],
    languageOptions: { parserOptions: { project: true } },
  },
];
