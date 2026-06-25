- I want to create a vocabulary learning app that is based on the gameplay of the game "The Typing of the Dead"
- This should be an application that I can install on a Mac computer (universal binary)
- It should be possible to maximize the window screen

# Vocabulary
- Use vocablist.txt as the wordlist
- Use the word, the part of speech, and the initial definition.  The example sentences in parentheses are not very interesting so we will replace them with more interesting definitions (see the # Definitions section)

# Gameplay
- In "The Typing of the Dead", the player has to quickly type sequences of characters or words to kill the zombies.  
As the game progresses, the player is presented with increasingly complex things to type and the zombies attack faster.
The goal is to teach typing fluency.  In this variation, the goal is not typing speed but learning vocabulary.

# Level types
Levels rotate through three challenge types in order (the type for a level is (level-1) mod 3):
- Type 1 (levels 1, 4, 7, …): match the WORD to its definition — see "Word-to-definition levels".
- Type 2 (levels 2, 5, 8, …): fill in the blank — see "Fill-in-the-blank levels".
- Type 3 (levels 3, 6, 9, …): match the DEFINITION to its word — see "Definition-to-word levels".

# Word-to-definition levels (Type 1)
Each zombie should clearly show a vocabulary word. The player must match the vocabulary word to its' definition to 
kill the zombie.  If the player chooses the wrong definition, the zombie should attack a bit faster. 
There are three zombie variants, drawn (via SwiftUI Canvas) as small shaded, painterly figures rather than flat
emoji - a green shambler, a purple ghoul with stringy hair, and a hooded reaper skull - each with gradient-shaded
skin/clothing, tattered robes, reaching clawed arms, a sunken face and glowing eyes, in the muted palette of the
graveyard background.

The top part of the screen should be the zombie attack zone. The bottom part will show one of 4 possible definitions for the 
zombie's vocabulary word - one of them should be correct, two should be plausible but incorrect, and one should be obviously 
wrong.  The correct definition should randomly rotate between what is shown first, second, third, fourth. 
The player can click "space" to choose that answer or "J" to advance through the other possible options.

The zombie attack zone uses a per-level background image (from reference-images/backgrounds/, bundled under
Resources/backgrounds/), scaled to fill the zone with a dark top-to-bottom gradient overlay so the falling zombies
and their text stay legible.  Levels that are a multiple of 5 (5, 10, 15, ...) use one of the "sf-" prefixed images;
all other levels use one of the remaining (non-"sf-") images.  "sf-" images are reserved exclusively for
multiple-of-5 levels.  Within each pool, levels are filled in order with images not yet used by that pool; once a
pool runs out of images, further levels of that kind use a plain black background.  Assignments are persisted to
~/Library/Application Support/WordsOfTheDead/background_assignments.json so a given level always keeps the same
background - adding more images later assigns them to the next currently-black higher levels without disturbing any
existing assignment.

When the player chooses correctly, the zombie with that word will be defeated and the bottom part of the screen should 
refresh to show "CORRECT".  The zombie falling should freeze while the top part of the screen is replaced with
the word, the part of speech, and the 'fun' definition.  
That text should wrap at a comfortable reading width - 50-75 characters per line. 
The fun definition should be left-justified, not centered, with appropriate equal sized margins to left and right
That should stay on-screen for 3 seconds before refreshing to the next zombie falling and the next set of definitions to rotate through
The vocabulary word within the fun definition should be bold and yellow, to make it stand out more


# Fill-in-the-blank levels (Type 2)
Each zombie should show a sentence with a blank where one of the vocabulary words would appear.
For example, if the word is "lucid" the sentence could be "Her explanation was so _____ that even the toddler understood" 
because the sentence makes sense if you substitute the ____ for the word "lucid"
The bottom part of the screen should show two possible words that could complete the sentence - one should be the correct
vocabulary word and the other should be an incorrect but plausible word.  
If the fun definition/sentence uses an inflected form of the word (a different part of speech or tense than the listed
word - e.g. "abetted" instead of "abet", or "ostensibly" instead of "ostensible"), the correct choice must match the
exact form used in the sentence (so the blank reads correctly when filled in).
The player will type the F key to answer with the word on the left or J to answer with the word on the right.
If the answer is correct, the zombie falling should freeze while the top part of the screen should refresh to show the 
completed sentence with the vocabulary word replacing the ______ . The vocabulary word should appear in bold and yellow.
That should stay on screen for 3 seconds before refreshing and the next zombie falling.

# Definition-to-word levels (Type 3)
This is the reverse of Type 1.  Each zombie shows a short DEFINITION; the bottom of the screen rotates through 4
candidate words — one correct, plus distractors (preferring the same part of speech).  
The correct word should randomly rotate between what is shown first, second, third, fourth. 
The player can click "space" to choose that answer or "J" to advance through the other possible options.
  A wrong guess makes the zombie attack a bit faster, the same as the other types.
The reveal (word, part of speech, and fun definition for 3 seconds) works the same as the other level types.

The player starts with only one life.  The HUD shows Lives in the upper right.
The player starts with 0 correct answers.  The HUD shows Zombies Killed in the upper left.
The HUD is arranged in two columns to keep it short vertically: Zombies Killed and the
current Level (and the transient STREAK banner) on the upper left; Lives and the Mastered
count on the upper right.
Each time the player gets one correct, the Zombies Killed Counter should increment by 1
Each time the player gets 5 in a row correct, the upper left should briefly show "STREAK - you got a new life" 
and the Lives counter should increment by 1.
When the player has failed to answer correctly in time and the zombie reaches the bottom part of the screen, they will lose 
a life.  When they lose a life, the Lives counter will decrement by 1.  When the Lives counter reaches 0, the game is over.
The player starts on Level 1. The entire screen should show Level 1 briefly before the gameplay starts.
The level intro screen also shows the command/instructions for that level's challenge type (e.g. press SPACE,
or press F / J), so the player knows what to do.

The fall speed of the zombies should stay consistent during each level.
Each level is 10 words - once the user has gone through 10 words, the entire screen should be replaced briefly with 
Level [number] and then resume
Each time the player advances to the next level, zombie fall speed should increase by 1%.
On level 3, a second zombie should appear and start falling once the first zombie is 75% of the way down the screen.
In subsequent levels, the second zombie should appear and start falling 3% earlier 
(i.e. when the first zombie is at 72% down the screen, then 69% down the screen, etc.)
When a second (or later) zombie appears, it shows the vocabulary word / sentence / definition that naturally comes next
(the next item in the queue), not a duplicate of the current zombie.  If a level ends (after 10 words) while such a
preview zombie is still on screen, the word it was showing is carried over and played first in the next level, so the
"next" word the player saw is the one that actually comes next.


# Definitions
- Take the original provided definition and display the first part (do not include the parts in parentheses) 
- Then, using the provided definition, also write a more 'fun' sentence that serves to define the word in the context of ONE of the listed references
- Do not use multiple references in the same sentence - for example, a sentence that references The Simpsons should not also reference Jurassic Park
- It is okay to adapt the part of speech in order to make a more interesting definition.  For example, "ostensible" is an adjective but you could change it to "ostensibly" in the definition (if you do so, add (part of speech) after the definition
- For example, for the word "ostensible" you might use the definition "Jack and Ralph and the other boys in "Lord of the Flies" were ostensibly normal, polite, civilized young boys." (adverb) 

# References
- The Simpsons characters and episodes
- Cobra Kai characters and episodes
- Premier League soccer players
- Great British Bake-off hosts and situations
- Neighborhoods and famous landmarks in San Francisco
- funny things that cats, penguins, or seals might do
- Fencing (the sport)
- Scenarios from these books: Lord of the Flies, The Wild Robot, Hitchhiker’s Guide to the Galaxy, any Gordon Korman books, Jurassic Park, Farmer Boy

# Testing mode
Write all of the fun sentences to a single text file called funsentences.txt
Add a flag where I can run the game with a "--qa" which will show each of the sentences, in readable font, 10 on screen at
a time and arrow links to advance to the next set of 10.  Each sentence should have a checkbox next to it. I should be able
to click the checkbox if the sentence has some flaw - is incorrect, doesn't make sense, is incomplete, etc.
Once I've reviewed all of the fun sentences, read through all of them and take your best guess at how to correct them.
I should then be able to accept your correction or manually add my own.  The updated corrected sentences should be updated
back into normal gameplay.
The QA review screen uses a white background with black and green text (so the checkboxes are clearly visible) and a
larger, easy-to-read sentence font.  Run it with: open WordsOfTheDead.app --args --qa
Corrections are saved to ~/Library/Application Support/WordsOfTheDead/fun_overrides.json and layered on top of the bundled
fun_definitions.json so they appear in gameplay; they can later be merged permanently into data/fun_definitions.json.

# Learning system (spaced repetition)
The game tracks how well the player knows each word and uses that to decide which words to
show, so practice focuses on the words that need it.
- Spaced repetition: every word has a Leitner box (0-5) with a due date. A correct answer
  (killing the zombie) promotes the word to the next box with a longer review interval; a
  wrong answer or a timeout demotes it. The scheduler resurfaces overdue words, rests
  mastered ones, and still mixes in brand-new words so the player keeps learning.
- In-session re-queue: when the player misses a word (wrong guess or the zombie reaches the
  bottom), that word is re-queued to reappear 2-3 spawns later in the same session for
  immediate reinforcement (at most once per zombie).
- Mastery stages: each word is New (never attempted), Learning (in progress), or Known
  (box 4+, i.e. answered correctly enough times with spacing). The current stage is shown
  as a small badge on the reveal card, and the HUD shows a running "Mastered: N / total".
- Persistence: progress is saved to
  ~/Library/Application Support/WordsOfTheDead/learning_profile.json, keyed by the
  lowercased word, so it carries across launches.

# Scoring and combos
The HUD shows a Score (centered, top of screen) and a live combo multiplier.
- Each kill scores base points plus a speed bonus (more points for killing a zombie higher up the screen),
  multiplied by the current combo.
- The combo multiplier grows with the player's correct-answer streak (up to x5) and resets to x1 on any miss
  (wrong final answer or a zombie reaching the bottom).

# Difficulty tiers and adaptive speed
- Words are assigned a rough difficulty tier (0 easiest to 3 hardest) from their length and estimated syllable count
  (no word-frequency corpus is bundled). New words are introduced easiest-first, and harder tiers unlock as the player
  levels up: tier 0 at levels 1-2, then one additional tier every two levels.
- On top of the per-level speed curve, fall speed is nudged up or down by the player's recent accuracy (last 8 outcomes)
  so the difficulty rubber-bands toward the player's ability.

# Boss review rounds
Every 5th level (once the player has words worth reviewing) is a faster "BOSS REVIEW" level that draws only from words
the player has struggled with (missed or not yet mastered). The level intro and HUD indicate the boss level.  The boss review
levels will coincide with the "sf-" background visuals.

# Daily goal and streak
The game tracks how many words are practiced each day, with a daily goal of 20 words.
- The start screen and game-over screen show the current day streak (consecutive days the goal was met), today's
  progress (N / 20), and a small 7-day activity calendar.
- Per-day practice counts persist to ~/Library/Application Support/WordsOfTheDead/daily_goal.json.

# End-of-run summary
The game-over screen shows final score, zombies killed, accuracy, best streak, newly mastered words, and the number of
words to review from that run.  

# Pause
Pressing the P key during play pauses and resumes the game; a paused overlay is shown while paused.

# Player profiles and saved progress
The game remembers each player's progress under a name they choose.
- On first launch (no saved players), the game asks for a name before play begins.
- On subsequent launches, the player can "Continue as <name>" for any saved player (the list shows each
  player's best level and best score) or choose "New Player" to start fresh under a new name.
- Each player has their own independent learning profile (spaced-repetition mastery) and daily-goal history,
  stored under ~/Library/Application Support/WordsOfTheDead/players/<id>/ (learning_profile.json + daily_goal.json).
  The player roster lives in players.json.
- Player identity is the name's slug (case- and punctuation-insensitive), so creating a "new" player with a
  name matching an existing one continues that existing profile rather than duplicating it.
- Any progress earned before the player system existed (the legacy top-level learning_profile.json /
  daily_goal.json) is migrated into the FIRST player ever created, exactly once, so no early progress is lost.
  After migrating, the legacy files are consumed (renamed to *.migrated.json) and a `legacyMigrated` flag is set,
  so every subsequent new player ALWAYS starts from zero mastered words — even if the roster is later reset.
- The start screen shows the current player's name with a "Switch" button to return to the player-select screen.
- Best level, best score, games played, and last-played time are recorded per player at game over.

