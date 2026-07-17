const questions = [
    {
        text: "Pick a rainy day activity",
        answers: [
            { label: "Write something down in a diary", type: "romantic" },
            { label: "Get cozy with tea and a book near the chimney", type: "daydreamer" },
            { label: "Go for a walk, dance under the rain", type: "wanderer" },
            { label: "Plan the next trip with friends", type: "adventurer" }
        ]
    },
    {
        text: "Pick a color for the sky",
        answers: [
            { label: "Gray, rainy, just before a rainbow", type: "daydreamer" },
            { label: "Storm clouds, thunders, hailing ", type: "adventurer" },
            { label: "Wide open black with millions of stars", type: "wanderer" },
            { label: "Gold, orange, just before sunset", type: "romantic" },
        ]
    },
    {
        text: "Pick an evening activity",
        answers: [
            { label: "Walking somewhere you've never been to", type: "wanderer" },
            { label: "Write a love letter to someone", type: "romantic" },
            { label: "Imagining and writing around", type: "daydreamer" },
            { label: "Going out of town to explore other places", type: "adventurer" }
        ]
    },
    {
        text: "Pick a sound to fall asleep to",
        answers: [
            { label: "Nothing, just your own thoughts", type: "daydreamer" },
            { label: "Wind, or a rain in the distance", type: "wanderer" },
            { label: "Calming / meditation music", type: "romantic" },
            { label: "Nothing — you're already asleep from exhaustion", type: "adventurer" }
        ]
    },
    {
        text: "What dream do you have?",
        answers: [
            { label: "Find love and live happily ever after", type: "romantic" },
            { label: "Become a novelist for an important editorial", type: "daydreamer" },
            { label: "Explore the world, travelling around", type: "wanderer" },
            { label: "Do extreme sports (skiing, surfing...)", type: "adventurer" }
        ]
    },
]

const results = {
    daydreamer: {
        type: "a daydreamer",
        title: "The Little Prince",
        desc: "You live half in this world and half in a better one that comes from inside you"
    },
    wanderer: {
        type: "a wanderer",
        title: "Wuthering Heights",
        desc: "Restless, wild, and always drawn toward the horizon"
    },
    romantic: {
        type: "a romantic",
        title: "Jane Eyre",
        desc: "Quietly intense, and more devoted than you know"
    },
    adventurer: {
        type: "an adventurer",
        title: "The Hobbit",
        desc: "You didn't ask for the adventure, but you'll take it anyways, that's just who you are"
    }
}

let current = 0 
const scores = { daydreamer: 0, wanderer: 0, romantic: 0, adventurer: 0}

function render() {
    const box = document.getElementById('quiz-box')

    if(current < questions.length) {
        const q = questions[current]
        box.innerHTML =  "<p class='quiz-progress'>Question " + (current + 1) + " of " + questions.length + "</p>" +
            "<h2 class='quiz-question'>" + q.text + "</h2>" +
            "<div class='quiz-answers'>" +
            q.answers.map((a, i) => "<button class='quiz-answer' data-i='" + i + "'>" + a.label + "</button>").join("") +
            "</div>";

        box.querySelectorAll('.quiz-answer').forEach(btn => {
            btn.addEventListener('click', () => {
                const type = q.answers[Number(btn.dataset.i)].type;
                scores[type]++;
                current++;
                render();
            });
        });
    } else {
        const winner = Object.keys(scores).reduce((a, b) => (scores[a] >= scores[b] ? a : b));
        const r = results[winner];
        box.innerHTML =
            "<div class='post-card quiz-result'>" +
            "<span class='quiz-header'>Your book</span>" +
            "<p class='quiz-sub'>You are "+ "<span>" + r.type + "</span>" + "</p>" +
            "<h2 class='post-card-title'>" + r.title + "</h2>" +
            "<p class='post-excerpt'>" + r.desc + "</p>" +
            "<button class='btn btn-primary' onclick='location.reload()'>Go again</button>" +
            "</div>";
    }
}

render()