# Task: add an extension point

When: a feature cannot attach to an existing point (ARC-04).
1. Architect persona. Write why the existing points do not fit.
2. Define the contract (schema or port), stability (`experimental` first), owner, rules that apply.
3. Add a row to `registry/extension-points.yaml`; document in `architecture/extension-fabric.md`.
4. ADR if the point is public or crosses a trust boundary.
5. Contract test fixtures (valid and invalid) before implementation.
6. Then build the feature through the point.
