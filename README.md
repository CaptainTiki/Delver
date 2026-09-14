# Delver

See [HANDOFF.md](HANDOFF.md) for the accepted combat baseline and laptop continuation notes.
The development notes below are chronological; earlier values may be superseded.

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

### Spacing playtest

Sword reach is now 1.8 meters and the goblin's attack query is 1.2 meters
(measured from the query origin to the target collision surface). The axe uses
1.4 meters. Reach values are direct distances, no longer square roots.
The temporary IN REACH cue uses the same query as your attack. It describes
current spacing, not a guaranteed hit if the target moves during your windup.
The enemy shows WINDUP, STRIKE, and RECOVERING above its head for this playtest.
It commits facing and position for a 0.8-second windup, 0.18-second strike,
and 1.1-second recovery. Player swing recovery now ends at 0.6 seconds.
Try baiting a swing, stepping backward, then stepping in to hit the recovery.
These are tuning aids; the reused blade animation still needs visual playtesting.
The regression scene must also print SPACING_TEST: PASS.

### Connected sword cuts

The player's old slash animation is replaced during attacks by a procedural
shoulder/elbow/wrist pose sequence: right-to-left diagonal, return cut, then
heavier descending finish. Source animation assets remain unchanged.
Click once per cut; another click near the end of the current commitment queues
one follow-up. Holding attack does not repeat. Each follow-up costs 25 stamina.
The third cut adds 2 damage and has a longer recovery; it cannot chain a fourth.
Guard or dodge can take over after the current cut's commitment finishes.
Attack movement retains 90% speed, with no forced lunge or hit stop.

Contact now sweeps the visible blade through the active portion of each cut,
with a maximum of one victim per cut. CLOSE RANGE is only a proximity aid;
it no longer claims that the center ray guarantees blade contact. The first
spacing-playtest notes above describe the earlier range-query implementation.
The pose and timing constants are in player_state_slashing.gd for further tuning.
The regression scene must also print COMBO_TEST: PASS.

### Combo feedback pass

Follow-up clicks are accepted from 0.05 seconds into a cut through its recovery,
with only one follow-up stored. The next attack still waits for commitment to
finish; there is no extra input-listening pause. The sequence is slightly slower.
Each cut now costs 15 stamina (45 for all three, down from 75), leaving room
for defense and additional enemies. The third cut raises the hand higher,
finishes lower, and rolls the blade 90 degrees so its edge leads the descent.

Next experiment: a small forward lunge on the third cut only, with committed
recovery that leaves the player exposed to other enemies. Not enabled yet.

### Crossing-cut motion

The first diagonal carries upward on the left during follow-through. A queued
second attack cuts from upper left to lower right, making an X with the opener.
Without a follow-up, the hand retracts toward the body before returning to ready.
Late follow-ups start from the current recovery pose without snapping back.

### Natural follow-through pass

The first cut carries outward around the left shoulder and may leave the frame
before rising into the cross cut. Small torso turns move the shoulder without
turning the camera, and elbow bend adapts to the hand position. Arm posing uses
body facing with partial look pitch instead of being fixed entirely to the view.
Combo timing, input buffering, stamina costs, and active damage windows are unchanged.
