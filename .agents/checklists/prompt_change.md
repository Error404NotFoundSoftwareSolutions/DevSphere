# Prompt change checklist

- [ ] Prompt lives in a versioned file with an owner; version bumped.
- [ ] Untrusted content is delimited and described as data (AIR-01).
- [ ] Output is schema-validated (AIR-08).
- [ ] Eval suite run before and after; scores recorded with model ID and parameters.
- [ ] Red-team set run; unsafe-action rate is 0.
- [ ] Token/cost impact noted.
