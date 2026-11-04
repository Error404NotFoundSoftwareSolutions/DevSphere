# Idea scoring rubric

Score each 1 (poor) to 5 (excellent). The score informs the owner; it never decides.

| Criterion | Question | Weight |
|---|---|---|
| Fit | Does it serve the goal and the chosen user (Q-004)? | 3 |
| Value | How much does the user gain? Is there evidence? | 3 |
| Effort | Person-weeks to first usable slice (5 = under 1) | 2 |
| Risk | Security, legal, trust-model, maintenance burden (5 = low) | 3 |
| Reversibility | Can we remove it cleanly if wrong? (5 = delete a module) | 2 |
| Leverage | Does it reuse existing capabilities or unlock others? | 2 |

`score = sum(weight * rating) / sum(weight * 5)`.
- >= 0.75: propose RFC.  0.5 to 0.75: park or shrink.  < 0.5: drop unless the owner insists.

Red flags that force an owner conversation regardless of score: touches scoring/trust (TRU), handles credentials, needs a core fork patch, adds a recurring cost, has unclear licensing.
