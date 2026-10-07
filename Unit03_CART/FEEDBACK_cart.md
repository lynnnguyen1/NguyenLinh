# Feedback on the CART assignment

Any comments inserted directly into your files are marked `#CLAUDE>>` (written by
Claude, an AI) or `#DAN>>` (written by Dan). Find them all by searching for `>>`;
`grep -rn '>>' .` lists every one. They are ordinary code comments, so your code
runs exactly as it did before. Claude's comments carry no grade and Claude does
not grade; any grade for this assignment comes from Dan, at the end of his
section below.

## Claude Feedback

You worked through all seven models, cross-validating each one by refitting on
every fold, and your "Linh's comment" blocks show you interpreting results as
you go: spotting that bagging's OOB and in-sample predictions differ, comparing
each new model with the last. Day 7 is done correctly: the random forest, fit on
all the training data, scored once on the test set.

Most worth working on:

- **The 1-SE rule.** You took the row with the lowest xerror. The rule then
  steps back to the simplest tree within one SE of it.
- **The xgboost result.** 0.660 is chance level for three classes. That points
  to the prediction reshaping step, not to gradient boosting failing (see the
  comment in the CV loop).
- **Day 6 experimentation.** Try a couple of settings for each boosting method
  and let CV choose.

## Dan Feedback

Excellent work! Lots of comments, you are obviously grappling with the ideas. 
Please make sure to search for ">>" and read all the specific comments in the 
code, since you can learn a few things and see the reason for a few minor bugs. 

Grade: S+