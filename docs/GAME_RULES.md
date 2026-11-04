# Rules in the first playable milestone

## English checkers (8×8)

- Twelve men per side on the playable squares.
- Men move and capture diagonally forward.
- Kings move and capture one square diagonally in any direction.
- Captures are compulsory.
- A multiple capture must be completed.
- When several capture sequences exist, the player may choose a legal sequence.
- Promotion ends the move.

Reference: World Checkers/Draughts Federation English rules:
https://wcdf.net/rules/rules_of_checkers_english.pdf

## Spanish draughts (8×8)

- Twelve men per side.
- Men make quiet moves diagonally forward.
- Men capture diagonally both forward and backward.
- Kings are flying kings and can move any unobstructed diagonal distance.
- Kings capture an opposing piece at range and may land on any empty square beyond it.
- Captures are compulsory.
- The sequence capturing the greatest number of pieces is mandatory.
- Promotion ends the man’s move in this initial implementation.

A Spanish 64-square rules reference describing compulsory maximum captures and flying-king captures:
https://www.flyordie.com/es/damas64/reglas

## Known omissions

This milestone does not yet adjudicate repetition and long-draw rules, tournament clocks, notation, online play, or all federation edge cases. The implementation must be validated against the exact Spanish federation ruleset chosen for tournament compatibility before making tournament-grade claims.
