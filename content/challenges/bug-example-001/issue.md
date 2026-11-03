<!--
User story: US-R2-2 Define and validate a challenge (Sprint 11, R2)
Requirements: FR-BUG-001..002, FR-BUG-012..013
Implemented here: R2: the issue text a student reads
-->

# Page 2 repeats the last item of page 1

Steps: call `paginate(items, page=2, size=3)`. Expected: items 4 to 6. Actual: items 3 to 5.
