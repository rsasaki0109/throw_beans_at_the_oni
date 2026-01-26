// Oni Blaster - Bean Throwing Battle
// GitHub Pages Version

const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');

// Responsive canvas sizing
function resizeCanvas() {
    const maxWidth = Math.min(window.innerWidth - 40, 800);
    const maxHeight = Math.min(window.innerHeight - 150, 600);
    const aspectRatio = 4 / 3;

    if (maxWidth / aspectRatio <= maxHeight) {
        canvas.width = maxWidth;
        canvas.height = maxWidth / aspectRatio;
    } else {
        canvas.height = maxHeight;
        canvas.width = maxHeight * aspectRatio;
    }
}
resizeCanvas();
window.addEventListener('resize', resizeCanvas);

// Game state
const game = {
    score: 0,
    timeLeft: 10,
    isPlaying: false,
    beans: [],
    onis: [],
    particles: [],
    scorePopups: [],
    lastTime: 0,
    throwCooldown: 0,
    isHolding: false
};

// Oni class
class Oni {
    constructor() {
        this.size = 60 + Math.random() * 30;
        this.x = Math.random() * (canvas.width - this.size * 2) + this.size;
        this.y = Math.random() * (canvas.height - this.size * 2 - 100) + this.size + 50;
        this.vx = (Math.random() - 0.5) * 3;
        this.vy = (Math.random() - 0.5) * 2;
        this.color = Math.random() > 0.7 ? '#ff4444' : '#4a90d9';
        this.points = this.color === '#ff4444' ? 30 : 10;
        this.bounceTimer = 0;
        this.hit = false;
        this.hitTimer = 0;
    }

    update(dt) {
        if (this.hit) {
            this.hitTimer -= dt;
            if (this.hitTimer <= 0) this.hit = false;
        }

        this.x += this.vx;
        this.y += this.vy;
        this.bounceTimer += dt * 5;

        // Bounce off walls
        if (this.x < this.size || this.x > canvas.width - this.size) {
            this.vx *= -1;
            this.x = Math.max(this.size, Math.min(canvas.width - this.size, this.x));
        }
        if (this.y < this.size + 50 || this.y > canvas.height - this.size) {
            this.vy *= -1;
            this.y = Math.max(this.size + 50, Math.min(canvas.height - this.size, this.y));
        }
    }

    draw() {
        ctx.save();
        ctx.translate(this.x, this.y + Math.sin(this.bounceTimer) * 5);

        // Flash white when hit
        if (this.hit) {
            ctx.globalAlpha = 0.5 + Math.sin(this.hitTimer * 30) * 0.5;
        }

        // Body
        ctx.fillStyle = this.color;
        ctx.beginPath();
        ctx.arc(0, 0, this.size * 0.8, 0, Math.PI * 2);
        ctx.fill();

        // Horns
        ctx.fillStyle = '#ffd700';
        ctx.beginPath();
        ctx.moveTo(-this.size * 0.4, -this.size * 0.6);
        ctx.lineTo(-this.size * 0.2, -this.size * 1.1);
        ctx.lineTo(0, -this.size * 0.6);
        ctx.fill();
        ctx.beginPath();
        ctx.moveTo(this.size * 0.4, -this.size * 0.6);
        ctx.lineTo(this.size * 0.2, -this.size * 1.1);
        ctx.lineTo(0, -this.size * 0.6);
        ctx.fill();

        // Eyes
        ctx.fillStyle = 'white';
        ctx.beginPath();
        ctx.arc(-this.size * 0.25, -this.size * 0.1, this.size * 0.2, 0, Math.PI * 2);
        ctx.arc(this.size * 0.25, -this.size * 0.1, this.size * 0.2, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = 'black';
        ctx.beginPath();
        ctx.arc(-this.size * 0.25, -this.size * 0.05, this.size * 0.1, 0, Math.PI * 2);
        ctx.arc(this.size * 0.25, -this.size * 0.05, this.size * 0.1, 0, Math.PI * 2);
        ctx.fill();

        // Mouth
        ctx.strokeStyle = 'white';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(0, this.size * 0.2, this.size * 0.3, 0.2, Math.PI - 0.2);
        ctx.stroke();

        // Fangs
        ctx.fillStyle = 'white';
        ctx.beginPath();
        ctx.moveTo(-this.size * 0.2, this.size * 0.35);
        ctx.lineTo(-this.size * 0.15, this.size * 0.55);
        ctx.lineTo(-this.size * 0.1, this.size * 0.35);
        ctx.fill();
        ctx.beginPath();
        ctx.moveTo(this.size * 0.2, this.size * 0.35);
        ctx.lineTo(this.size * 0.15, this.size * 0.55);
        ctx.lineTo(this.size * 0.1, this.size * 0.35);
        ctx.fill();

        ctx.restore();
    }
}

// Bean class
class Bean {
    constructor(x, y, targetX, targetY) {
        this.x = x;
        this.y = y;
        const angle = Math.atan2(targetY - y, targetX - x);
        const speed = 15;
        this.vx = Math.cos(angle) * speed;
        this.vy = Math.sin(angle) * speed;
        this.size = 8;
        this.alive = true;
    }

    update() {
        this.x += this.vx;
        this.y += this.vy;

        // Remove if off screen
        if (this.x < 0 || this.x > canvas.width || this.y < 0 || this.y > canvas.height) {
            this.alive = false;
        }
    }

    draw() {
        ctx.fillStyle = '#8B4513';
        ctx.beginPath();
        ctx.ellipse(this.x, this.y, this.size, this.size * 0.7,
                    Math.atan2(this.vy, this.vx), 0, Math.PI * 2);
        ctx.fill();

        // Highlight
        ctx.fillStyle = '#D2691E';
        ctx.beginPath();
        ctx.ellipse(this.x - 2, this.y - 2, this.size * 0.4, this.size * 0.3,
                    Math.atan2(this.vy, this.vx), 0, Math.PI * 2);
        ctx.fill();
    }
}

// Particle class for hit effects
class Particle {
    constructor(x, y, color) {
        this.x = x;
        this.y = y;
        this.vx = (Math.random() - 0.5) * 10;
        this.vy = (Math.random() - 0.5) * 10;
        this.size = Math.random() * 6 + 2;
        this.color = color;
        this.life = 1;
        this.decay = 0.02 + Math.random() * 0.02;
    }

    update() {
        this.x += this.vx;
        this.y += this.vy;
        this.vy += 0.3; // gravity
        this.life -= this.decay;
    }

    draw() {
        ctx.globalAlpha = this.life;
        ctx.fillStyle = this.color;
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = 1;
    }
}

// Score popup class
class ScorePopup {
    constructor(x, y, score) {
        this.x = x;
        this.y = y;
        this.score = score;
        this.life = 1;
        this.vy = -2;
    }

    update() {
        this.y += this.vy;
        this.life -= 0.02;
    }

    draw() {
        ctx.globalAlpha = this.life;
        ctx.fillStyle = this.score >= 30 ? '#ff6b6b' : '#ffd700';
        ctx.font = `bold ${24 + this.score}px Arial`;
        ctx.textAlign = 'center';
        ctx.fillText(`+${this.score}`, this.x, this.y);
        ctx.globalAlpha = 1;
    }
}

// Initialize game
function initGame() {
    game.score = 0;
    game.timeLeft = 10;
    game.beans = [];
    game.onis = [];
    game.particles = [];
    game.scorePopups = [];
    game.throwCooldown = 0;

    // Spawn initial onis
    for (let i = 0; i < 3; i++) {
        game.onis.push(new Oni());
    }

    updateUI();
}

// Start game
function startGame() {
    initGame();
    game.isPlaying = true;
    game.lastTime = performance.now();
    document.getElementById('start-screen').classList.add('hidden');
    document.getElementById('result-screen').classList.add('hidden');
    requestAnimationFrame(gameLoop);

    // Start timer
    game.timerInterval = setInterval(() => {
        if (game.isPlaying) {
            game.timeLeft--;
            updateUI();
            if (game.timeLeft <= 0) {
                endGame();
            }
        }
    }, 1000);
}

// End game
function endGame() {
    game.isPlaying = false;
    clearInterval(game.timerInterval);
    document.getElementById('final-score').textContent = game.score;
    document.getElementById('result-screen').classList.remove('hidden');
}

// Update UI
function updateUI() {
    document.getElementById('score').textContent = `Score: ${game.score}`;
    document.getElementById('timer').textContent = `Time: ${game.timeLeft}`;
}

// Throw bean
function throwBean(targetX, targetY) {
    if (!game.isPlaying || game.throwCooldown > 0) return;

    const startX = canvas.width / 2;
    const startY = canvas.height - 30;
    game.beans.push(new Bean(startX, startY, targetX, targetY));
    game.throwCooldown = 100; // ms between throws
}

// Check collisions
function checkCollisions() {
    for (let bean of game.beans) {
        if (!bean.alive) continue;

        for (let oni of game.onis) {
            const dx = bean.x - oni.x;
            const dy = bean.y - oni.y;
            const dist = Math.sqrt(dx * dx + dy * dy);

            if (dist < oni.size * 0.8 + bean.size) {
                bean.alive = false;
                oni.hit = true;
                oni.hitTimer = 0.2;
                game.score += oni.points;
                updateUI();

                // Create particles
                for (let i = 0; i < 10; i++) {
                    game.particles.push(new Particle(bean.x, bean.y, oni.color));
                }

                // Create score popup
                game.scorePopups.push(new ScorePopup(oni.x, oni.y - oni.size, oni.points));

                // Respawn oni at new position
                oni.x = Math.random() * (canvas.width - oni.size * 2) + oni.size;
                oni.y = Math.random() * (canvas.height - oni.size * 2 - 100) + oni.size + 50;
                oni.vx = (Math.random() - 0.5) * 3;
                oni.vy = (Math.random() - 0.5) * 2;

                break;
            }
        }
    }
}

// Game loop
function gameLoop(timestamp) {
    if (!game.isPlaying) return;

    const dt = (timestamp - game.lastTime) / 1000;
    game.lastTime = timestamp;

    // Update cooldown
    game.throwCooldown = Math.max(0, game.throwCooldown - dt * 1000);

    // Auto-throw when holding
    if (game.isHolding && game.throwCooldown <= 0) {
        throwBean(game.targetX || canvas.width / 2, game.targetY || canvas.height / 2);
    }

    // Update entities
    game.onis.forEach(oni => oni.update(dt));
    game.beans.forEach(bean => bean.update());
    game.particles.forEach(p => p.update());
    game.scorePopups.forEach(p => p.update());

    // Check collisions
    checkCollisions();

    // Remove dead entities
    game.beans = game.beans.filter(b => b.alive);
    game.particles = game.particles.filter(p => p.life > 0);
    game.scorePopups = game.scorePopups.filter(p => p.life > 0);

    // Draw
    draw();

    requestAnimationFrame(gameLoop);
}

// Draw everything
function draw() {
    // Clear canvas
    ctx.fillStyle = '#87CEEB';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Draw grass
    const gradient = ctx.createLinearGradient(0, canvas.height * 0.7, 0, canvas.height);
    gradient.addColorStop(0, '#98FB98');
    gradient.addColorStop(1, '#228B22');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, canvas.height * 0.7, canvas.width, canvas.height * 0.3);

    // Draw entities
    game.onis.forEach(oni => oni.draw());
    game.beans.forEach(bean => bean.draw());
    game.particles.forEach(p => p.draw());
    game.scorePopups.forEach(p => p.draw());

    // Draw player (bean thrower)
    ctx.fillStyle = '#8B4513';
    ctx.beginPath();
    ctx.arc(canvas.width / 2, canvas.height - 20, 15, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#D2691E';
    ctx.beginPath();
    ctx.arc(canvas.width / 2 - 3, canvas.height - 23, 5, 0, Math.PI * 2);
    ctx.fill();
}

// Event handlers
function getCanvasPosition(e) {
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;

    if (e.touches) {
        return {
            x: (e.touches[0].clientX - rect.left) * scaleX,
            y: (e.touches[0].clientY - rect.top) * scaleY
        };
    }
    return {
        x: (e.clientX - rect.left) * scaleX,
        y: (e.clientY - rect.top) * scaleY
    };
}

// Mouse events
canvas.addEventListener('mousedown', (e) => {
    if (!game.isPlaying) return;
    const pos = getCanvasPosition(e);
    game.isHolding = true;
    game.targetX = pos.x;
    game.targetY = pos.y;
    throwBean(pos.x, pos.y);
});

canvas.addEventListener('mousemove', (e) => {
    if (!game.isPlaying || !game.isHolding) return;
    const pos = getCanvasPosition(e);
    game.targetX = pos.x;
    game.targetY = pos.y;
});

canvas.addEventListener('mouseup', () => {
    game.isHolding = false;
});

canvas.addEventListener('mouseleave', () => {
    game.isHolding = false;
});

// Touch events
canvas.addEventListener('touchstart', (e) => {
    e.preventDefault();
    if (!game.isPlaying) return;
    const pos = getCanvasPosition(e);
    game.isHolding = true;
    game.targetX = pos.x;
    game.targetY = pos.y;
    throwBean(pos.x, pos.y);
});

canvas.addEventListener('touchmove', (e) => {
    e.preventDefault();
    if (!game.isPlaying) return;
    const pos = getCanvasPosition(e);
    game.targetX = pos.x;
    game.targetY = pos.y;
});

canvas.addEventListener('touchend', (e) => {
    e.preventDefault();
    game.isHolding = false;
});

// Keyboard events
document.addEventListener('keydown', (e) => {
    if (e.code === 'Space' && game.isPlaying && !e.repeat) {
        game.isHolding = true;
        game.targetX = canvas.width / 2;
        game.targetY = canvas.height / 2;
        throwBean(game.targetX, game.targetY);
    }
});

document.addEventListener('keyup', (e) => {
    if (e.code === 'Space') {
        game.isHolding = false;
    }
});

// Button events
document.getElementById('start-btn').addEventListener('click', startGame);
document.getElementById('retry-btn').addEventListener('click', startGame);

// Initial draw
draw();
