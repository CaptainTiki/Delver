# Delver

#game graphics inspiration: Bloodwright


## Questions and Ideas
	* Hub could be a Tavern
	** Barman and Barmaid could be vendors - other patrons give quests etc
	** When the game opens, you build your character - then we flash "you meet in a tavern" as we load the hub. 

## Combat prototype

Pick up the sword near the entrance with E, then approach the goblin in the foyer.
WASD moves, Shift runs, Space jumps, left mouse swings, right mouse holds guard,
Q dodges in the movement direction (backward when stationary), and R throws.
After death, R restarts the encounter.

A swing costs 25 stamina and commits for 0.75 seconds. Dodge costs 30, lasts
0.35 seconds, and avoids hits from 0.05 to 0.25 seconds. Frontal guard costs
30 stamina per hit; insufficient stamina breaks guard and lets damage through.
Stamina recovers while moving/resting with guard lowered, after a short delay.
The goblin commits its facing during attacks, deals 6 damage once per swing,
and leaves a recovery opening. Existing animations are reused for this first pass.
Enemy pursuit is direct movement, without navigation around complex obstacles.

Run the regression scene with Godot:
`godot --headless --path . res://tests/combat_test.tscn --quit-after 600 --log-file ./combat-test.log`
Both COMBAT_TEST and ENEMY_TEST must report PASS, with no errors.
