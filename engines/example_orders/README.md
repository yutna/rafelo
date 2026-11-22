# example_orders

An example product module to learn from, not a feature to keep. It shows a
filtered and paginated list, a show page, new/edit with the form token and a
conflict, a deferred chart, and an export job. Its pages render one screen;
screens arrange containers and components; containers use hooks; and the
`domain/` and `forms/` folders stay framework-free (FE-01). Nothing outside
`example_*` may depend on it (GEN-08); delete it once your own first module can
serve as the reference.
