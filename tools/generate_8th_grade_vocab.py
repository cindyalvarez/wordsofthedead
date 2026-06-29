#!/usr/bin/env python3
"""Generate a 500-word tier-0 vocabulary list for levels 1-50."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADVANCED_PATH = ROOT / "data" / "vocab.json"
OUTPUT_PATH = ROOT / "data" / "vocab_8th_grade.json"

THEME_ORDER = [
    "simpsons",
    "cobra",
    "premier",
    "bakeoff",
    "sf",
    "animals",
    "fencing",
    "books",
]

THEMES = {
    "simpsons": [
        {"subject": "Bart", "scene": "the Kwik-E-Mart roof", "item": "a skateboard"},
        {"subject": "Lisa", "scene": "the Springfield band room", "item": "a saxophone case"},
        {"subject": "Homer", "scene": "Moe's parking lot", "item": "a pink donut box"},
        {"subject": "Marge", "scene": "the Simpson kitchen", "item": "a blue grocery bag"},
        {"subject": "Milhouse", "scene": "the arcade", "item": "an oversized comic book"},
        {"subject": "Maggie", "scene": "the living room", "item": "a red pacifier"},
        {"subject": "Mr. Burns", "scene": "the nuclear plant hallway", "item": "a gold pen"},
        {"subject": "Ned Flanders", "scene": "the Leftorium", "item": "a left-handed mug"},
        {"subject": "Krusty", "scene": "the TV studio", "item": "a cream pie"},
        {"subject": "Sideshow Bob", "scene": "the theater stage", "item": "a suspicious rake"},
    ],
    "cobra": [
        {"subject": "Miguel", "scene": "the Cobra Kai dojo", "item": "red sparring gloves"},
        {"subject": "Sam", "scene": "the Miyagi-Do yard", "item": "bonsai clippers"},
        {"subject": "Robby", "scene": "the All Valley arena", "item": "a tournament medal"},
        {"subject": "Johnny Lawrence", "scene": "his Reseda apartment", "item": "a black headband"},
        {"subject": "Daniel LaRusso", "scene": "the LaRusso Auto showroom", "item": "car keys"},
        {"subject": "Tory", "scene": "the school hallway", "item": "a trophy-case key"},
        {"subject": "Hawk", "scene": "the batting cage", "item": "blue hair spray"},
        {"subject": "Demetri", "scene": "the cafeteria", "item": "an open laptop"},
        {"subject": "Chozen", "scene": "the training deck", "item": "a wooden practice drum"},
        {"subject": "Kreese", "scene": "the old dojo office", "item": "a cobra poster"},
    ],
    "premier": [
        {"subject": "Haaland", "scene": "the Etihad tunnel", "item": "a match ball"},
        {"subject": "Salah", "scene": "the Anfield touchline", "item": "a red scarf"},
        {"subject": "Saka", "scene": "the Emirates training ground", "item": "a captain's armband"},
        {"subject": "Son", "scene": "the Tottenham stadium steps", "item": "a corner flag"},
        {"subject": "Bruno Fernandes", "scene": "the Old Trafford tunnel", "item": "a referee whistle"},
        {"subject": "Virgil van Dijk", "scene": "the penalty box", "item": "goalkeeper gloves"},
        {"subject": "Cole Palmer", "scene": "the Stamford Bridge bench", "item": "a blue water bottle"},
        {"subject": "Isak", "scene": "the St James' Park gate", "item": "a black-and-white scarf"},
        {"subject": "Alisson", "scene": "the goalmouth", "item": "a pair of muddy boots"},
        {"subject": "Pep Guardiola", "scene": "the sideline", "item": "a strategy board"},
    ],
    "bakeoff": [
        {"subject": "Paul Hollywood", "scene": "the Bake Off tent", "item": "a rolling pin"},
        {"subject": "Prue Leith", "scene": "the judging table", "item": "a pastel cake stand"},
        {"subject": "Noel Fielding", "scene": "the gingham altar", "item": "a tray of scones"},
        {"subject": "Alison Hammond", "scene": "the prep bench", "item": "a bright apron"},
        {"subject": "a star baker", "scene": "the proving drawer station", "item": "a loaf tin"},
        {"subject": "a nervous baker", "scene": "the bunting-lined counter", "item": "a piping bag"},
        {"subject": "the pastry chef", "scene": "pastry week", "item": "a stack of macarons"},
        {"subject": "the bread week winner", "scene": "the cooling rack", "item": "a showstopper loaf"},
        {"subject": "the biscuit artist", "scene": "the chocolate table", "item": "a biscuit dragon"},
        {"subject": "the showstopper champion", "scene": "the cake stand", "item": "a wobbling meringue tower"},
    ],
    "sf": [
        {"subject": "a cable car conductor", "scene": "Lombard Street", "item": "a cable car ticket"},
        {"subject": "a tourist guide", "scene": "Pier 39", "item": "a sourdough loaf"},
        {"subject": "a skater", "scene": "Dolores Park", "item": "a board sticker"},
        {"subject": "a ranger", "scene": "the Alcatraz dock", "item": "a ferry pass"},
        {"subject": "a photographer", "scene": "Twin Peaks", "item": "a camera strap"},
        {"subject": "a vendor", "scene": "the Ferry Building", "item": "a market tote"},
        {"subject": "a runner", "scene": "Crissy Field", "item": "a windbreaker"},
        {"subject": "a drummer", "scene": "the Chinatown gate", "item": "a red lantern"},
        {"subject": "a neighbor", "scene": "the Painted Ladies sidewalk", "item": "a Victorian postcard"},
        {"subject": "a hiker", "scene": "the Lands End trail", "item": "a foggy map"},
    ],
    "animals": [
        {"subject": "a cat", "scene": "the windowsill", "item": "a ball of yarn"},
        {"subject": "a kitten", "scene": "the couch cushion", "item": "a tiny bell"},
        {"subject": "a penguin", "scene": "the icy ledge", "item": "a fish bucket"},
        {"subject": "a seal", "scene": "the harbor rocks", "item": "a wet flipper"},
        {"subject": "a sea lion", "scene": "the Pier 39 float", "item": "a salty bark"},
        {"subject": "a tabby", "scene": "the bookshelf", "item": "a scratched bookmark"},
        {"subject": "a tuxedo cat", "scene": "the rooftop", "item": "a glow-in-the-dark collar"},
        {"subject": "a penguin chick", "scene": "the snow bank", "item": "a pebble"},
        {"subject": "a harbor seal", "scene": "the tide pool", "item": "a shiny shell"},
        {"subject": "a rescue cat", "scene": "the blanket fort", "item": "a soft paw"},
    ],
    "fencing": [
        {"subject": "a foil fencer", "scene": "the practice piste", "item": "a silver mask"},
        {"subject": "an epee captain", "scene": "the strip edge", "item": "a scoring cord"},
        {"subject": "a sabre sprinter", "scene": "the club locker", "item": "a white glove"},
        {"subject": "the referee", "scene": "the scoring table", "item": "a red card"},
        {"subject": "a beginner fencer", "scene": "the warm-up line", "item": "a weapon bag"},
        {"subject": "the team captain", "scene": "the medal stand", "item": "a tournament ribbon"},
        {"subject": "a coach", "scene": "the lesson strip", "item": "a stopwatch"},
        {"subject": "a left-handed fencer", "scene": "the training hall", "item": "a foil tip"},
        {"subject": "a parry expert", "scene": "the finals piste", "item": "a lame jacket"},
        {"subject": "a bout judge", "scene": "the gym bleachers", "item": "a score sheet"},
    ],
    "books": [
        {"subject": "Arthur Dent", "scene": "the Heart of Gold", "item": "a blue towel"},
        {"subject": "Roz", "scene": "the island cliff", "item": "a repair kit"},
        {"subject": "Ralph", "scene": "the beach from Lord of the Flies", "item": "a conch shell"},
        {"subject": "Dr. Grant", "scene": "the Jurassic Park jeep", "item": "a fossil brush"},
        {"subject": "Almanzo", "scene": "the Farmer Boy wagon", "item": "a lunch pail"},
        {"subject": "Ford Prefect", "scene": "the spaceship corridor", "item": "the Guide"},
        {"subject": "a Gordon Korman hero", "scene": "the school roof", "item": "a fake hall pass"},
        {"subject": "Lex Murphy", "scene": "the visitor center", "item": "a flashlight"},
        {"subject": "Piggy", "scene": "the fire hill", "item": "his cracked specs"},
        {"subject": "a Wild Robot gosling", "scene": "the forest clearing", "item": "a feather bundle"},
    ],
}

EVENTS = [
    "the graveyard fog got thicker",
    "the last flashlight flickered",
    "the barricade started to shake",
    "someone yelled, 'Run!'",
    "a siren echoed down the block",
    "the rescue van rolled away",
    "the rooftop ladder slipped",
    "the gate chains clanked twice",
    "the map blew into a puddle",
    "the zombie horde changed direction",
    "the moon slid behind a cloud",
    "the radio crackled with static",
    "the gym lights blinked on and off",
    "the floorboards groaned underfoot",
    "an alarm bell started ringing",
    "the wind pushed open a side door",
    "a crow landed on the fence",
    "the power cut out for a second",
    "the old truck coughed back to life",
    "the safe-room latch finally clicked",
]

NOUN_TEMPLATES = [
    "At {scene}, {subject} learned that **{word}** means {definition} when {item} slipped away and {event}.",
    "While zombies groaned near {scene}, {subject} remembered that **{word}** is {definition} just as {item} became the next clue.",
    "During a wild night at {scene}, {subject} saw that **{word}** means {definition} after {item} showed up and {event}.",
    "At {scene}, {subject} treated **{word}** as {definition} before grabbing {item} and heading for safety.",
]

VERB_TEMPLATES = [
    "When the graveyard gate rattled by {scene}, {subject} had to **{word}**—{definition}—before {item} vanished.",
    "{subject_cap} chose to **{word}**, meaning {definition}, while racing through {scene} and protecting {item}.",
    "At {scene}, {subject} tried to **{word}**—{definition}—as {event} and {item} bounced across the floor.",
    "With zombies closing in at {scene}, {subject} would **{word}** if it meant {definition} and saving {item}.",
]

ADJ_TEMPLATES = [
    "{subject_cap} looked **{word}**—{definition}—at {scene} while holding {item} and listening for zombies.",
    "At {scene}, everyone called {subject} **{word}** because {definition} fit the moment and even {item} seemed impressed.",
    "While crossing {scene}, {subject} stayed **{word}**—{definition}—as {event} and {item} wobbled dangerously.",
    "With {item} tucked under one arm, {subject} seemed **{word}** at {scene}, meaning {definition}.",
]

ADV_TEMPLATES = [
    "{subject_cap} moved **{word}**—{definition}—through {scene} with {item} in hand as {event}.",
    "At {scene}, {subject} answered **{word}**, meaning {definition}, before passing over {item}.",
    "While zombies shuffled nearby, {subject} worked **{word}**—{definition}—at {scene} and kept track of {item}.",
    "{subject_cap} handled {item} **{word}**—{definition}—while escaping near {scene}.",
]

NOUNS_RAW = """
ability|the power or skill to do something
accident|something bad that happens unexpectedly
action|something done on purpose
adventure|an exciting or unusual experience
advice|helpful ideas about what to do
age|the number of years someone has lived
air|the mixture of gases we breathe
answer|a reply to a question
area|a particular place or region
art|creative work such as drawing or music
athlete|a person skilled in sports
attention|careful focus on something
balance|a steady position or fair mix
beach|sandy or rocky land by water
beauty|the quality of being pleasing to see
beginning|the start of something
belief|an idea accepted as true
book|pages bound together for reading
bridge|a structure that crosses over something
buddy|a close friend
camp|a place where people stay outdoors
care|serious concern or helpful attention
chance|an opportunity or possibility
challenge|a difficult task to overcome
character|a person in a story or a person's nature
choice|the act of choosing or the option picked
city|a large town where many people live
class|a group lesson or school period
climate|the usual weather of a place
cloud|a mass of tiny water drops in the sky
coach|a person who trains a team or player
color|the appearance of something like red or blue
comfort|a feeling of ease and relaxation
community|a group of people living or working together
contest|a competition to see who does best
courage|the strength to face fear
course|a set path or series of lessons
crowd|a large group of people
culture|the shared beliefs, arts, and customs of a group
danger|the possibility of harm
day|a period of twenty-four hours
decision|a choice made after thinking
demand|a strong need or request
design|a plan or pattern for making something
detail|a small but important part
difference|the way things are not the same
direction|the way something points or moves
discovery|the act of finding something new
discussion|a talk where people share ideas
distance|the amount of space between things
dream|thoughts and images during sleep or a big hope
effort|hard work put into something
energy|the power to move or do work
error|a mistake
event|something that happens, especially planned
example|something that shows what another thing is like
fact|something known to be true
family|people related to each other or living together
feature|an important part of something
feeling|an emotion or sense inside you
field|open land or an area of study or play
focus|special attention on one thing
force|power used to move or control something
forest|a large area filled with trees
freedom|the power to act or choose without control
friend|a person you like and trust
game|an activity with rules for fun or competition
garden|a place where plants are grown
goal|something you try to reach or achieve
habit|something done regularly
health|the condition of body and mind
heart|the organ that pumps blood or the center of feelings
hero|a person admired for courage or action
history|the study or story of the past
hope|a feeling of wanting something good to happen
idea|a thought or plan
image|a picture or mental impression
importance|the quality of being meaningful or valuable
improvement|a change that makes something better
interest|a feeling of wanting to learn more
island|land surrounded by water
job|work done for pay or a task
journey|the act of traveling from one place to another
joy|great happiness
judgment|an opinion formed after thinking
knowledge|facts and understanding learned over time
language|a system of words used to communicate
leader|a person who guides others
lesson|something learned or a period of teaching
library|a place where books and media are shared
life|the state of being alive
light|brightness that lets us see
limit|the farthest point allowed
location|the place where something is
luck|success that seems to happen by chance
map|a drawing that shows places
memory|something remembered or the ability to remember
message|information sent from one person to another
method|a way of doing something
middle|the center part of something
minute|a unit of time equal to sixty seconds
mistake|something done incorrectly
moment|a very short period of time
mystery|something hard to explain or understand
nation|a country with its own government
nature|the living world and outdoor environment
need|something required or necessary
neighbor|a person living nearby
noise|a sound, especially a loud unwanted one
notice|a sign or short written message
number|a count or amount shown with digits
object|a thing that can be seen or touched
ocean|the large saltwater covering most of Earth
offer|a chance or proposal to give something
opinion|a belief or view that may differ
order|the arrangement of things or a command
parent|a mother or father
park|a public outdoor place for people to enjoy
partner|a person who works or acts with another
party|a social gathering or group in a contest
pattern|a repeated design or way things happen
peace|a calm state without fighting
people|human beings in general
plan|a set of steps for doing something
player|a person who takes part in a game
point|a sharp end, a main idea, or a score mark
power|strength or control
practice|repeated work to improve a skill
problem|a difficulty that needs a solution
progress|movement forward or improvement over time
project|a planned piece of work
purpose|the reason something is done
question|words used to ask for information
reason|a cause or explanation
record|stored information or the best result so far
relationship|the way people or things are connected
resource|something useful that can help
result|the final effect or outcome
river|a large stream of flowing water
rule|an official direction about what is allowed
safety|freedom from danger or harm
school|a place where people learn
season|one of the four parts of the year
secret|something kept hidden
sense|good judgment or one of the body's ways of noticing
shape|the form of something
shelter|a place that protects from danger or weather
sign|a mark or object that gives information
skill|the ability to do something well
solution|an answer to a problem
spirit|energy, attitude, or the nonphysical part of a person
sport|a physical game or activity
star|a giant ball of burning gas or a famous person
story|a tale about events or people
strength|the power to stay strong or keep going
style|a special way something is done or looks
success|the achievement of a goal
surprise|something unexpected
task|a piece of work to finish
team|a group working together
temperature|a measure of how hot or cold something is
theater|a place for plays or movies
thought|an idea formed in the mind
time|the ongoing flow of moments
tool|an object used to do a job
tradition|a custom followed over time
trouble|difficulty or problems
truth|what is real or correct
value|how useful, important, or costly something is
victory|success in a contest or struggle
"""

VERBS_RAW = """
accept|to say yes to or receive
achieve|to reach a goal
act|to do something or perform
adapt|to change to fit new conditions
add|to put something more in
admire|to respect or enjoy looking at
advise|to give helpful guidance
allow|to let something happen
appear|to come into view
apply|to put to use or request something
argue|to speak with disagreement
arrange|to put in order or plan
ask|to say something to get an answer
avoid|to stay away from
believe|to think something is true
belong|to be a proper part of something
build|to make by putting parts together
calculate|to work out an amount or answer
call|to speak or phone to someone
celebrate|to honor with joy
change|to make or become different
choose|to pick from options
collect|to gather together
compare|to look for similarities and differences
compete|to try to win against others
complete|to finish fully
connect|to join together
consider|to think carefully about
continue|to keep going
create|to make something new
decide|to choose after thinking
defend|to protect against attack or criticism
deliver|to bring something to a place or person
describe|to tell what something is like
develop|to grow or cause to grow
discover|to find or learn something new
discuss|to talk about
divide|to separate into parts
doubt|to feel unsure about
edit|to change writing or media to improve it
encourage|to give hope or support
enjoy|to take pleasure in
escape|to get away from
examine|to look at carefully
exist|to be real or present
expand|to become larger
explain|to make clear
explore|to travel or study to learn more
face|to deal with directly
fail|to not succeed
figure|to understand or solve
find|to locate or discover
finish|to complete the end of
follow|to go after or obey
forgive|to stop being angry about a wrong
gather|to bring together
grow|to become larger or older
guard|to watch and protect
guess|to give an answer without being sure
happen|to take place
help|to make something easier
hide|to keep out of sight
imagine|to form a picture in the mind
improve|to make better
include|to contain as a part
increase|to make or become greater
influence|to affect how someone thinks or acts
inform|to give knowledge or facts
inspire|to fill with ideas or courage
invite|to ask someone to join or come
join|to become part of something
judge|to form an opinion or decide fairly
jump|to push off the ground
keep|to hold on to or continue
know|to understand or be aware of
laugh|to make sounds of amusement
lead|to guide or go first
learn|to gain knowledge or skill
listen|to pay attention to sound
live|to be alive or stay somewhere
look|to use the eyes to see
love|to care deeply about
manage|to handle successfully
measure|to find size, amount, or length
meet|to come together
miss|to fail to catch or be without
move|to change place or position
observe|to watch carefully
occur|to happen
open|to make not closed
organize|to arrange neatly or plan
overcome|to succeed against a problem
participate|to take part
pass|to move by or give to another
perform|to do, present, or carry out
play|to take part for fun or sport
prepare|to get ready
protect|to keep safe from harm
prove|to show that something is true
push|to press or move away
reach|to get to or touch
read|to look at words and understand them
realize|to understand clearly
receive|to get something given or sent
reduce|to make smaller or less
reflect|to think deeply or show an image back
relax|to become less tense
remember|to keep in mind or bring back to mind
repeat|to say or do again
reply|to answer with words
report|to tell information in an organized way
rescue|to save from danger
respect|to treat with honor and care
rest|to relax or stop working
return|to go back
review|to look over again
rise|to move upward
save|to keep, protect, or rescue
search|to look carefully for
seem|to appear to be
select|to choose carefully
share|to use or give jointly
shine|to give off light or brightness
show|to let be seen
solve|to find an answer
speak|to say words
spend|to use time or money
stand|to be upright on feet
start|to begin
stay|to remain in one place or condition
study|to learn with focused effort
succeed|to do what you set out to do
suggest|to offer an idea
support|to hold up or help
swim|to move through water
teach|to help someone learn
thank|to tell someone you are grateful
think|to use the mind
travel|to go from place to place
trust|to believe someone is honest or safe
try|to make an effort
understand|to know what something means
unite|to join together
use|to put into action
visit|to go see a place or person
wait|to stay until something happens
walk|to move on foot
want|to wish for or desire
watch|to look at for a time
win|to come out first or succeed
wonder|to think about with curiosity
work|to do a job or effort
worry|to feel uneasy about
write|to put words on a page or screen
whisper|to speak very softly
yell|to shout loudly
zoom|to move very fast
borrow|to take for a short time and return
carry|to hold and move something
fix|to repair or make right
"""

ADJECTIVES_RAW = """
active|full of energy or movement
amazed|very surprised
ancient|very old
angry|feeling mad
brave|ready to face fear
bright|full of light or intelligence
busy|full of activity
calm|peaceful and not upset
careful|paying close attention to avoid mistakes
certain|sure and without doubt
cheerful|happy and positive
clever|quick to learn or understand
cloudy|filled with clouds or unclear
comfortable|relaxed and at ease
common|found often; not unusual
confident|sure of yourself
curious|eager to know more
daily|happening every day
dark|having little light
different|not the same
difficult|hard to do or understand
direct|straight and clear
distant|far away in space or time
eager|excited and ready
easy|not hard
fair|honest and reasonable
famous|known by many people
fast|moving quickly
favorite|liked more than others
fearless|not afraid
final|last in order
flexible|able to bend or change easily
friendly|kind and easy to like
gentle|calm, soft, and not rough
glad|pleased or happy
golden|made of gold or glowing warm yellow
grateful|thankful
great|very good or important
happy|feeling joy
healthy|strong and well
helpful|willing to help
honest|truthful and fair
huge|very large
important|valuable or significant
independent|able to act on your own
interesting|holding attention
kind|caring and helpful
large|big in size
late|happening after the expected time
lively|full of energy and spirit
local|nearby or from the area
lonely|feeling alone and sad
loud|making a strong sound
lucky|having good fortune
modern|relating to recent times
natural|found in nature; not made by people
neat|clean and well organized
nervous|worried or uneasy
normal|usual or expected
patient|able to wait calmly
peaceful|calm and quiet
playful|full of fun and energy
polite|showing good manners
popular|liked by many people
positive|hopeful or certain
powerful|having great strength or influence
proud|pleased with something done well
quick|fast in action or thought
quiet|making little noise
ready|prepared for action
real|true; not imagined
reliable|able to be trusted
safe|free from danger
serious|thoughtful, important, or not joking
sharp|having a fine edge or quick mind
shiny|reflecting light
simple|easy to understand or not fancy
skillful|good at doing something
slow|moving without speed
smart|clever or neat in style
smooth|even and without bumps
social|relating well with other people
special|different in a meaningful way
strong|having power or firmness
sudden|happening quickly and unexpectedly
sunny|full of sunlight or cheer
sure|certain
surprised|feeling unexpected wonder
sweet|tasting like sugar or being very kind
talented|having a natural skill
thankful|feeling grateful
thoughtful|showing careful thinking or kindness
tidy|clean and in order
tiny|very small
tough|strong and hard to break or defeat
true|correct and honest
unusual|not common
valuable|worth a lot or very useful
warm|giving comfortable heat
weak|lacking strength
wild|living freely or hard to control
willing|ready to do something
wise|showing good judgment
wonderful|extremely good
young|not old
adorable|very cute and lovable
alert|quick to notice things
alive|living; not dead
bold|brave and confident
bumpy|not smooth; full of bumps
chilly|slightly cold
creative|able to make new ideas
dusty|covered with dust
empty|containing nothing
fancy|special, decorative, or expensive-looking
fresh|new, clean, or just made
gigantic|extremely large
humble|modest and not bragging
itchy|causing a need to scratch
messy|untidy and disorganized
"""

ADVERBS_RAW = """
almost|not quite
always|at all times
bravely|in a courageous way
carefully|with caution and attention
certainly|without doubt
clearly|in an easy-to-understand way
closely|in a near or careful way
brightly|with strong light or cheer
eagerly|with excitement and interest
easily|without much trouble
evenly|in a smooth and equal way
finally|at the end
gently|in a soft and careful way
gladly|with pleasure
happily|in a joyful way
honestly|truthfully
kindly|in a caring way
loudly|with a lot of sound
mostly|for the biggest part
nearly|almost but not completely
neatly|in a clean and orderly way
never|at no time
often|many times
patiently|in a calm waiting way
proudly|with pride
quickly|at high speed
quietly|with little sound
really|truly or very much
safely|without danger
seriously|in an important or careful way
simply|in an easy and plain way
slowly|at low speed
smoothly|without problems or bumps
sometimes|at certain times but not always
soon|in a short time
suddenly|quickly and unexpectedly
surely|certainly
thoughtfully|in a careful or kind way
together|with each other
truly|honestly or really
usually|most of the time
warmly|in a friendly or warm way
widely|over a large area or by many people
wisely|with good judgment
actually|in fact
already|before now or earlier than expected
fully|completely
likely|probably
softly|in a quiet or gentle way
openly|in a way that is honest and public
"""

LEVEL_PATTERNS = (
    [["n", "n", "n", "n", "v", "v", "v", "adj", "adj", "adv"]] * 20
    + [["n", "n", "n", "v", "v", "v", "adj", "adj", "adj", "adv"]] * 20
    + [["n", "n", "n", "v", "v", "v", "v", "adj", "adj", "adv"]] * 10
)


def parse_group(raw: str, pos: str) -> list[dict[str, str]]:
    entries: list[dict[str, str]] = []
    for line in raw.strip().splitlines():
        word, definition = [part.strip() for part in line.split("|", 1)]
        entries.append({"word": word, "pos": pos, "shortDefinition": definition})
    return entries


def pick_theme(index: int, offset: int) -> dict[str, str]:
    theme_name = THEME_ORDER[(index + offset) % len(THEME_ORDER)]
    theme_entries = THEMES[theme_name]
    entry_index = (
        (index // len(THEME_ORDER)) * 3 + index * (offset + 2) + offset
    ) % len(theme_entries)
    return theme_entries[entry_index]


def build_fun_sentence(entry: dict[str, str], index: int) -> str:
    primary = pick_theme(index, 0)
    secondary = pick_theme(index, 3)
    tertiary = pick_theme(index, 5)
    event = EVENTS[index % len(EVENTS)]

    if entry["pos"] == "n":
        template = NOUN_TEMPLATES[index % len(NOUN_TEMPLATES)]
    elif entry["pos"] == "v":
        template = VERB_TEMPLATES[index % len(VERB_TEMPLATES)]
    elif entry["pos"] == "adj":
        template = ADJ_TEMPLATES[index % len(ADJ_TEMPLATES)]
    else:
        template = ADV_TEMPLATES[index % len(ADV_TEMPLATES)]

    return template.format(
        word=entry["word"],
        definition=entry["shortDefinition"],
        subject=primary["subject"],
        subject_cap=primary["subject"][:1].upper() + primary["subject"][1:],
        scene=secondary["scene"],
        item=tertiary["item"],
        event=event,
    )


def arrange_entries() -> list[dict[str, str]]:
    pools = {
        "n": parse_group(NOUNS_RAW, "n"),
        "v": parse_group(VERBS_RAW, "v"),
        "adj": parse_group(ADJECTIVES_RAW, "adj"),
        "adv": parse_group(ADVERBS_RAW, "adv"),
    }

    ordered: list[dict[str, str]] = []
    for pattern in LEVEL_PATTERNS:
        for pos in pattern:
            ordered.append(pools[pos].pop(0))

    if any(pools.values()):
        leftovers = {pos: len(items) for pos, items in pools.items() if items}
        raise ValueError(f"Unused words remained after arranging levels: {leftovers}")

    return ordered


def load_advanced_words() -> set[str]:
    if not ADVANCED_PATH.exists():
        return set()
    data = json.loads(ADVANCED_PATH.read_text(encoding="utf-8"))
    return {entry["word"].strip().lower() for entry in data if entry.get("word")}


def validate(entries: list[dict[str, object]], advanced_words: set[str]) -> None:
    if len(entries) != 500:
        raise ValueError(f"Expected 500 entries, found {len(entries)}")

    seen: set[str] = set()
    overlaps: list[str] = []
    for idx, entry in enumerate(entries):
        word = str(entry["word"]).lower()
        if word in seen:
            raise ValueError(f"Duplicate word found: {word}")
        seen.add(word)
        if word in advanced_words:
            overlaps.append(word)

        if entry["pos"] not in {"n", "v", "adj", "adv"}:
            raise ValueError(f"Bad part of speech for {word}: {entry['pos']}")
        if entry["tier"] != 0:
            raise ValueError(f"Tier must be 0 for {word}")
        if f"**{entry['word']}**" not in str(entry["funSentence"]):
            raise ValueError(f"Highlighted word missing from fun sentence for {word}")

        expected_level = idx // 10 + 1
        expected_position = idx % 10 + 1
        if entry["level"] != expected_level or entry["levelPosition"] != expected_position:
            raise ValueError(f"Bad level mapping for {word}")

    if overlaps:
        preview = ", ".join(sorted(overlaps)[:20])
        raise ValueError(f"Words overlap with advanced vocab.json: {preview}")


def main() -> None:
    advanced_words = load_advanced_words()
    base_entries = arrange_entries()

    output: list[dict[str, object]] = []
    for idx, entry in enumerate(base_entries):
        output.append(
            {
                "word": entry["word"],
                "pos": entry["pos"],
                "shortDefinition": entry["shortDefinition"],
                "funSentence": build_fun_sentence(entry, idx),
                "level": idx // 10 + 1,
                "levelPosition": idx % 10 + 1,
                "tier": 0,
            }
        )

    validate(output, advanced_words)
    OUTPUT_PATH.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(output)} entries to {OUTPUT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
