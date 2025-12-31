set -l MODE $argv[1]
if test -z "$MODE"
    set MODE "type"
end

set -l DATA "
😀 grinning face face smile happy joy :D grin
😃 grinning face with big eyes face happy joy haha :D :) smile funny
😄 grinning face with smiling eyes face happy joy funny haha laugh like :D :) smile
😁 beaming face with smiling eyes face happy smile joy kawaii
😆 grinning squinting face happy joy lol satisfied haha face glad XD laugh
😅 grinning face with sweat face hot happy laugh sweat smile relief
🤣 rolling on the floor laughing face rolling floor laughing lol haha rofl
😂 face with tears of joy face cry tears weep happy happytears haha
🙂 slightly smiling face face smile
🙃 upside down face face flipped silly smile
😉 winking face face happy mischievous secret ;) smile eye
😊 smiling face with smiling eyes face smile happy flushed crush embarrassed shy joy
😇 smiling face with halo face angel heaven halo
🥰 smiling face with hearts face love like affection valentines infatuation crush hearts adore
😍 smiling face with heart eyes face love like affection valentines infatuation crush heart
🤩 star struck face smile starry eyes grinning
😘 face blowing a kiss face love like affection valentines infatuation kiss
😗 kissing face love like face 3 valentines infatuation kiss
☺️ smiling face face blush massage happiness
😚 kissing face with closed eyes face love like affection valentines infatuation kiss
😙 kissing face with smiling eyes face affection valentines infatuation kiss
😋 face savoring food happy joy tongue smile face silly yummy nom delicious savouring
😛 face with tongue face prank childish playful mischievous smile tongue
😜 winking face with tongue face prank childish playful mischievous smile wink tongue
🤪 zany face face goofy crazy
😝 squinting face with tongue face prank playful mischievous smile tongue
🤑 money mouth face face rich dollar money
🤗 hugging face face smile hug
🤭 face with hand over mouth face whoops shock surprise
🤫 shushing face face quiet shhh
🤔 thinking face face hmmm think consider
🤐 zipper mouth face face sealed zipper secret
🤨 face with raised eyebrow face distrust scepticism disapproval disbelief surprise
😐 neutral face indifference meh :| neutral
😑 expressionless face face indifferent - - meh deadpan
😶 face without mouth face hellokitty
😏 smrking face face smile mean prank smug sarcasm
😒 unamused face indifference bored straight face serious sarcasm unimpressed skeptical dubious side eye
🙄 face with rolling eyes face eyeroll frustrated
😬 grimacing face face grimace teeth
🤥 lying face face lie pinocchio
😌 relieved face face relaxed phew massage happiness
😔 pensive face face sad depressed upset
😪 sleepy face face tired rest nap
🤤 drooling face face
😴 sleeping face face tired sleepy night zzz
😷 face with medical mask face sick ill disease
🤒 face with thermometer sick temperature thermometer cold fever
🤕 face with head bandage injured clumsy bandage hurt
🤢 nauseated face face vomit gross green sick throw up ill
🤮 face vomiting face sick
🤧 sneezing face face gesundheit sneeze sick allergy
🥵 hot face face feverish heat red sweating
🥶 cold face face blue freezing frozen frostbite icicles
🥴 woozy face face dizzy intoxicated tipsy wavy
😵 dizzy face spent unconscious xox dizzy
🤯 exploding head face shocked mind blown
🤠 cowboy hat face face cowgirl hat
🥳 partying face face celebration woohoo
😎 smiling face with sunglasses face cool smile summer beach sunglass
🤓 nerd face face nerdy geek dork
🧐 face with monocle face stuffy wealthy
😕 confused face face indifference huh weird hmmm :/
😟 worried face face concern nervous :(
🙁 slightly frowning face face frowning disappointed sad upset
☹️ frowning face face sad upset frown
😮 face with open mouth face surprise impressed wow whoa :O
😯 hushed face face woo shh
😲 astonished face face xox surprised poisoned
😳 flushed face face blush shy flattered sex
🥺 pleading face face begging mercy
😦 frowning face with open mouth face aw what
😧 anguished face face stunned nervous
😨 fearful face face scared terrified nervous oops huh
😰 anxious face with sweat face nervous sweat
😥 sad but relieved face face phew sweat nervous
😢 crying face face tears sad depressed upset :'(
😭 loudly crying face face cry tears sad upset depressed sob
😱 face screaming in fear face munch scared omg
😖 confounded face face confused sick unwell oops :S
😣 persevering face face sick no upset oops
😞 disappointed face face sad upset depressed :(
😓 downcast face with sweat face hot sad tired exercise
😩 weary face face tired sleepy sad frustrated upset
😫 tired face sick whine upset frustrated
🥱 yawning face tired sleepy
😤 face with steam from nose face gas phew proud pride
😡 pouting face angry mad hate despise
😠 angry face mad face annoyed frustrated
🤬 face with symbols on mouth face swearing cursing cssing profanity expletive
😈 smiling face with horns devil horns
👿 angry face with horns devil angry horns
💀 skull dead skeleton creepy death
☠️ skull and crossbones poison danger deadly scary death pirate evil
💩 pile of poo hankey shitface fail turd shit
🤡 clown face face
👹 ogre monster red mask halloween scary creepy devil demon japanese ogre
👺 goblin red evil mask monster scary creepy japanese goblin
👻 ghost halloween spooky scary
👽 alien UFO paul weird outer space
👾 alien monster game arcade play
🤖 robot computer machine bot
😺 grinning cat animal cats happy smile
😸 grinning cat with smiling eyes animal cats smile
😹 cat with tears of joy animal cats haha happy tears
😻 smiling cat with heart eyes animal love like affection cats valentines heart
😼 cat with wry smile animal cats smirk
😽 kissing cat animal cats kiss
🙀 weary cat animal cats munch scared scream
😿 crying cat animal tears weep sad cats upset cry
😾 pouting cat animal cats
🙈 see no evil monkey monkey animal nature haha
🙉 hear no evil monkey animal monkey nature
🙊 speak no evil monkey monkey animal nature omg
💋 kiss mark face lips love like affection valentines
💌 love letter email like affection envelope valentines
💘 heart with arrow love like heart affection valentines
💝 heart with ribbon love valentines
💖 sparkling heart love like affection valentines
💗 growing heart like love affection valentines pink
💓 beating heart love like affection valentines pink heart
💞 revolving hearts love like affection valentines
💕 two hearts love like affection valentines heart
💟 heart decoration purple-square love like
❣️ heart exclamation decoration love
💔 broken heart sad sorry break heart heartbreak
❤️ red heart love like valentines
🧡 orange heart love like affection valentines
💛 yellow heart like like affection valentines
💚 green heart love like affection valentines
💙 blue heart love like affection valentines
💜 purple heart love like affection valentines
🤎 brown heart coffee
🖤 black heart evil
🤍 white heart pure
"

set -l selected_line (echo -e "$DATA" | string trim --left | fuzzel --match-mode fzf --dmenu)

if test -z "$selected_line"
    exit 0
end

set -l emoji (string split -m 1 ' ' -- "$selected_line")[1]

switch "$MODE"
    case type
        wtype "$emoji"; or wl-copy "$emoji"
    case copy
        wl-copy "$emoji"
    case both
        wtype "$emoji" &>/dev/null
        wl-copy "$emoji"
    case '*'
        echo "Usage: (status filename) [type|copy|both]" >&2
        exit 1
end
