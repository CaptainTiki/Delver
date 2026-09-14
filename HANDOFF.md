# Delver handoff — 2026-09-13

## Start here tomorrow

The player sword motion is now an accepted baseline. John's final feedback was:
"now that feels and looks good!" Preserve this motion and input feel while
working on the next layer. Do not restart the animation experiment from scratch.

First on the laptop: open the project, let assets import, run the foyer, pick up
the sword with E, and press backtick for unlimited stamina. Check that the
crossing combo and outward follow-through match the accepted desktop version.
Then agree on the next experiment below before changing the baseline.

## Game direction

Sulfur-inspired dungeon diving/extraction with deliberate melee: commit, swing,
dodge, block, stamina. The main tension is deciding how far to push, whether
healing will turn up, and what to keep in limited bags. Skilled execution should
allow damage-free progress. Readable enemies, not memorized surprise traps.
Aim for responsive rhythmic exchanges rather than a slow, solved backstep drill.

## Accepted sword behavior

- Cut 1: upper right to lower left.
- Follow-through carries outward around the left shoulder, out of frame, then
  rises. Small torso turns move the shoulder without turning the camera; elbow
  bend adapts, and the arm follows body facing with partial look pitch.
- Cut 2: upper left to lower right, making an X with cut 1. This must remain
  visibly distinct from returning to ready.
- Cut 3: higher-to-lower descending finish, blade rolled so the edge leads.
- If no follow-up is requested, the hand retracts toward the body into ready.
  Late follow-ups start from the current pose, without snapping back.
- One click per cut. Buffer opens 0.05 seconds into each cut and lasts through
  recovery. One next attack can be queued; holding attack does not repeat.
- Cut durations: 0.80 / 0.64 / 0.92 seconds. Commitment ends at
  0.54 / 0.44 / 0.68 seconds. Guard/dodge can take over after commitment.
- Each attack costs 15 stamina; full combo costs 45. Third cut adds 2 damage.
- Attack movement keeps 90% speed. No forced lunge; no hit stop.
- Damage sweeps the visible blade during the active cut, once per cut at most.
  Currently one victim per cut. CLOSE RANGE is a proximity aid, not a guarantee.
- Temporary HUD shows cut number, queued follow-up, and recovery/defense state.

## Testing controls

WASD move, Shift run, Space jump, E pick up, left mouse attack, right mouse hold
front guard, Q dodge (backward if stationary), R throw; R retries after death.
Backtick toggles unlimited stamina and refills it immediately. HUD shows mode.
It covers attacks, dodge and guard costs; health/damage remain normal. Toggle is
local to the player instance and resets when the scene restarts.

## What the iterations taught us

The original slash looked upright, robotic and weightless; timed damage did not
match visible contact. Severe attack slowdown felt like walking through mud.
Making the enemy very slow/readable solved damage avoidance but was not fun.
Returning diagonally upward for cut 2 looked like resetting to ready. The X
pattern fixed that. Keeping the blade in frame made follow-through artificial;
allowing the sword outside the frame with body motion was explicitly approved.
John dislikes hit stop. Do not add it as a default impact improvement.

## Next experiments — not implemented or approved as final design

1. Small forward lunge on the third cut only. John wants to try this eventually;
   heavy commitment should leave consequences when another enemy is present.
2. Better enemy impact responses: folding/recoiling with the slash direction;
   sustained hits break balance and stagger backward. Avoid pushing enemies
   out of reach on every hit. Current basic hurt/ragdoll behavior remains.
3. Revisit enemy pressure/rhythm now the sword feels good. Current goblin has
   deliberately generous windup/recovery and direct pursuit, without navigation.
   Blocking/dodging should have meaningful uses, not be unnecessary next to S.
4. Impact audio and other feedback may help later, without freezing the action.
5. Bags, healing, valuable loot, extraction and persistent progress remain future
   work; first establish the small combat encounter.

## Key files

- world/charactors/player/states/player_state_slashing.gd: procedural arm/wrist
  poses, body turn, combo timing, buffer, damage sweep and transitions.
- world/charactors/player/player.gd: stamina, backtick override, defense, movement.
- ui/combat_hud.gd: health/stamina, test toggle, range and combo cues.
- tests/combat_test.gd and .tscn: combat, enemy, spacing and combo checks.
- README.md: earlier chronological notes; some older values are superseded.

## Validation and environment

Latest headless run reports COMBAT_TEST, ENEMY_TEST, SPACING_TEST and COMBO_TEST:
PASS. These cover damage/guard/dodge/stamina/death, enemy attacks, a damage-free
bait/counter, and combo buffering/costs/three-cut cap/single-click release.
Rendered follow-through poses were inspected; John's live playtest is the key
feel validation. Tests do not prove animation quality or all multi-enemy behavior.

Desktop executable: D:/Godot/Godot_v4.6.3-stable_win64_console.exe.
Project declares Godot 4.7, but desktop validation ran with 4.6.3. On a fresh copy,
let the editor import resources before testing. Create .godot first and use an
absolute --log-file path: this machine crashed on startup when its log directory
was missing. Compatibility renderer was used for captured frames, not saved as
a project setting. .godot captures/logs are disposable and need not transfer.

Example (adjust executable and absolute log path for laptop):

    godot --headless --path . res://tests/combat_test.tscn --quit-after 600 --log-file <absolute-existing-directory>/combat-test.log

Require all four PASS lines and no script errors; exit code alone is insufficient.

## Transfer status at handoff

Last commit inspected: 560bb32 — 3 swing combo.
The accepted latest tuning was still UNCOMMITTED when this handoff was written:
README.md, tests/combat_test.gd, ui/combat_hud.gd,
world/charactors/player/player.gd,
world/charactors/player/states/player_state_slashing.gd.
This handoff is also new. No commit or push was performed for the handoff.
A laptop pull alone is not enough to obtain these working-copy changes unless
they are committed/pushed separately. Transfer the current working project or
publish the changes through the user's chosen Git workflow first.
