# Feedback on the Modularity assignment

Any comments inserted directly into your files are marked `#CLAUDE>>` (written by
Claude, an AI) or `#DAN>>` (written by Dan). Find them all by searching for `>>`;
`grep -rn '>>' .` lists every one. They are ordinary code comments, so your code
runs exactly as it did before. Claude's comments carry no grade and Claude does
not grade; any grade for this assignment comes from Dan, at the end of his
section below.

## Claude Feedback

**Running it.** Dan asked me to run every submission from a fresh pull and time it. From
inside your folder, `Rscript main.R` ran to completion first time, no fixes, in **55 seconds**,
and wrote all four PNGs. Two warnings from `geom_point()`: 292 temperature stations and 21
precipitation stations were dropped from the maps because the coordinates you take from each
station's first row are missing in that row (other rows of the same station may have them).

**What went well.** The structure is right: a one-station regression function, a loop function
that applies it with `min_obs` as an argument, and one plotting function each for histograms
and maps with every label passed in rather than typed. The 40-measurement rule counts real
values. Your modularity comments are honest about the process (scratch code first, then
functions; several rewrites), which is what lessons 3, 5 and 6 are about.

**Worth working on.**
- The one real correctness issue: a location is identified by `name` alone. Station names
  repeat across states, so `data[data$name == loc, ]` pools different stations into one
  regression. Group by state and name, or by lon and lat. This is also why your station counts
  differ from Dan's 3,207 and 268.
- `map_draw_func()` uses `us` from the global workspace without receiving it. The slides'
  ironclad rule: a function touches only what is passed in or created inside it.
- 40 and 0.1 are typed at the call sites several times; name them once at the top (lesson 1).
- `rbind` inside the loop copies the growing data frame on every pass; it is probably most of
  your 55 seconds. Preallocate and fill by index, as the slides' `popsim` does.
- Two of your tags read `#MODULARITY 4` and `#MODULARITY 6` rather than `#MODULARITY EXAMPLE -`,
  so a search for the required phrase misses them.

## Dan Feedback

Not sure why your write-up did not contain any of the figures you generated? Write-ups without
figures are about as exciting as dishwater. If you have figures, include them!

Your run time is 55s, which is slower than it could have been. For each station name, 
data[data$name == loc, ] rescans all the rows, and rbind regrows the results each pass. 
My posted solution actually makes the same mistake! It makes little difference, since
a run time of 55s compared to 7s (what you get without that mistake) is of no real
consequence, but if the run times were 100 times more a similar factor might matter.
Just letting you know.

Your major bug is relying on station name alone to identify a station. There are stations 
with the same name in different states, so this groups them and produces a trend that makes
no sense. Use lat/lon or at least state/name.

Good use of functions and good clarity on basically what each function does, but
you also need a header at the time that gives the precise interface. 

Good job overall.

Grade: S