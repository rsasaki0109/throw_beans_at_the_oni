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

// Achievements definition
const ACHIEVEMENTS = {
    firstBlood: { id: 'firstBlood', name: 'First Blood', desc: 'Hit your first Oni', icon: '👹', unlocked: false },
    combo5: { id: 'combo5', name: 'Combo Master', desc: 'Get a 5x combo', icon: '🔥', unlocked: false },
    combo10: { id: 'combo10', name: 'Combo Legend', desc: 'Get a 10x combo', icon: '💥', unlocked: false },
    score100: { id: 'score100', name: 'Century', desc: 'Score 100 points', icon: '💯', unlocked: false },
    score500: { id: 'score500', name: 'High Scorer', desc: 'Score 500 points', icon: '⭐', unlocked: false },
    score1000: { id: 'score1000', name: 'Oni Slayer', desc: 'Score 1000 points', icon: '👑', unlocked: false },
    redOni: { id: 'redOni', name: 'Red Hunter', desc: 'Hit 5 red Oni in one game', icon: '🔴', unlocked: false },
    perfectCombo: { id: 'perfectCombo', name: 'No Miss', desc: 'Finish with 10+ combo', icon: '✨', unlocked: false }
};

// Load saved data
function loadSaveData() {
    const saved = localStorage.getItem('oniBlasterSave');
    if (saved) {
        const data = JSON.parse(saved);
        return {
            highScore: data.highScore || 0,
            achievements: data.achievements || {}
        };
    }
    return { highScore: 0, achievements: {} };
}

// Save data
function saveData() {
    const data = {
        highScore: game.highScore,
        achievements: game.achievements
    };
    localStorage.setItem('oniBlasterSave', JSON.stringify(data));
}

// Game state
const saveData_loaded = loadSaveData();
const game = {
    score: 0,
    highScore: saveData_loaded.highScore,
    timeLeft: 10,
    isPlaying: false,
    beans: [],
    onis: [],
    clubs: [], // 鬼の金棒
    particles: [],
    scorePopups: [],
    achievementPopups: [],
    lastTime: 0,
    throwCooldown: 0,
    isHolding: false,
    // Combo system
    combo: 0,
    maxCombo: 0,
    comboTimer: 0,
    comboTimeout: 1.5, // seconds to maintain combo
    // Level system
    level: 1,
    redOniHits: 0,
    // Achievements
    achievements: saveData_loaded.achievements,
    // Player state
    player: {
        x: 0,
        y: 0,
        hp: 3,
        maxHp: 3,
        speed: 200,
        size: 20,
        invincible: 0 // 無敵時間
    },
    // Input state for movement
    keys: {
        up: false,
        down: false,
        left: false,
        right: false
    },
    // Virtual joystick for mobile
    joystick: {
        active: false,
        startX: 0,
        startY: 0,
        currentX: 0,
        currentY: 0
    }
};

// Achievement popup class
class AchievementPopup {
    constructor(achievement) {
        this.achievement = achievement;
        this.life = 3; // Show for 3 seconds
        this.y = -80;
        this.targetY = 60;
    }

    update(dt) {
        this.life -= dt;
        // Slide in animation
        if (this.y < this.targetY) {
            this.y += 200 * dt;
            if (this.y > this.targetY) this.y = this.targetY;
        }
        // Slide out when almost done
        if (this.life < 0.5) {
            this.y -= 200 * dt;
        }
    }

    draw() {
        const width = 250;
        const height = 60;
        const x = (canvas.width - width) / 2;

        ctx.save();
        ctx.globalAlpha = Math.min(1, this.life * 2);

        // Background
        ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
        ctx.roundRect(x, this.y, width, height, 10);
        ctx.fill();

        // Border
        ctx.strokeStyle = '#ffd700';
        ctx.lineWidth = 2;
        ctx.roundRect(x, this.y, width, height, 10);
        ctx.stroke();

        // Icon
        ctx.font = '30px Arial';
        ctx.textAlign = 'left';
        ctx.fillText(this.achievement.icon, x + 10, this.y + 42);

        // Text
        ctx.fillStyle = '#ffd700';
        ctx.font = 'bold 14px Arial';
        ctx.fillText('Achievement Unlocked!', x + 50, this.y + 22);
        ctx.fillStyle = 'white';
        ctx.font = '16px Arial';
        ctx.fillText(this.achievement.name, x + 50, this.y + 45);

        ctx.restore();
    }
}

// Club (金棒) class - thrown by Oni
class Club {
    constructor(x, y, targetX, targetY) {
        this.x = x;
        this.y = y;
        const angle = Math.atan2(targetY - y, targetX - x);
        const speed = 6;
        this.vx = Math.cos(angle) * speed;
        this.vy = Math.sin(angle) * speed;
        this.angle = angle;
        this.size = 12;
        this.alive = true;
    }

    update() {
        this.x += this.vx;
        this.y += this.vy;
        this.angle += 0.2; // 回転

        // Remove if off screen
        if (this.x < -50 || this.x > canvas.width + 50 ||
            this.y < -50 || this.y > canvas.height + 50) {
            this.alive = false;
        }
    }

    draw() {
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.rotate(this.angle);

        // 金棒の棒部分
        ctx.fillStyle = '#8B4513';
        ctx.fillRect(-20, -4, 40, 8);

        // 金棒の先端（トゲトゲ部分）
        ctx.fillStyle = '#444';
        ctx.beginPath();
        ctx.arc(15, 0, 8, 0, Math.PI * 2);
        ctx.fill();

        // トゲ
        ctx.fillStyle = '#666';
        for (let i = 0; i < 6; i++) {
            const spikeAngle = (i / 6) * Math.PI * 2;
            ctx.beginPath();
            ctx.moveTo(15 + Math.cos(spikeAngle) * 6, Math.sin(spikeAngle) * 6);
            ctx.lineTo(15 + Math.cos(spikeAngle) * 12, Math.sin(spikeAngle) * 12);
            ctx.lineTo(15 + Math.cos(spikeAngle + 0.3) * 6, Math.sin(spikeAngle + 0.3) * 6);
            ctx.fill();
        }

        ctx.restore();
    }
}

// Oni class
class Oni {
    constructor(speedMultiplier = 1) {
        this.size = 40 + Math.random() * 20; // サイズ縮小: 60-90 → 40-60
        this.x = Math.random() * (canvas.width - this.size * 2) + this.size;
        this.y = Math.random() * (canvas.height - this.size * 2 - 150) + this.size + 50;
        this.vx = (Math.random() - 0.5) * 3 * speedMultiplier;
        this.vy = (Math.random() - 0.5) * 2 * speedMultiplier;
        this.color = Math.random() > 0.7 ? '#ff4444' : '#4a90d9';
        this.points = this.color === '#ff4444' ? 30 : 10;
        this.bounceTimer = 0;
        this.hit = false;
        this.hitTimer = 0;
        this.throwCooldown = 2 + Math.random() * 2; // 金棒投げるクールダウン
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
        if (this.y < this.size + 50 || this.y > canvas.height - this.size - 100) {
            this.vy *= -1;
            this.y = Math.max(this.size + 50, Math.min(canvas.height - this.size - 100, this.y));
        }

        // 金棒を投げる
        this.throwCooldown -= dt;
        if (this.throwCooldown <= 0 && game.isPlaying) {
            this.throwClub();
            this.throwCooldown = 2.5 + Math.random() * 2; // 次の投げるまでの時間
        }
    }

    throwClub() {
        // プレイヤーに向かって金棒を投げる
        game.clubs.push(new Club(this.x, this.y, game.player.x, game.player.y));
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
            // Reset combo on miss
            if (game.combo > 0) {
                game.combo = 0;
            }
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
    constructor(x, y, score, combo = 0) {
        this.x = x;
        this.y = y;
        this.score = score;
        this.combo = combo;
        this.life = 1;
        this.vy = -2;
    }

    update() {
        this.y += this.vy;
        this.life -= 0.02;
    }

    draw() {
        ctx.globalAlpha = this.life;

        // Score text
        const comboColor = this.combo >= 10 ? '#ff00ff' : this.combo >= 5 ? '#ff6b6b' : '#ffd700';
        ctx.fillStyle = comboColor;
        ctx.font = `bold ${24 + Math.min(this.combo * 2, 20)}px Arial`;
        ctx.textAlign = 'center';
        ctx.fillText(`+${this.score}`, this.x, this.y);

        // Combo text
        if (this.combo > 1) {
            ctx.font = 'bold 16px Arial';
            ctx.fillStyle = comboColor;
            ctx.fillText(`${this.combo}x COMBO!`, this.x, this.y + 20);
        }

        ctx.globalAlpha = 1;
    }
}

// Unlock achievement
function unlockAchievement(id) {
    if (game.achievements[id]) return; // Already unlocked

    game.achievements[id] = true;
    ACHIEVEMENTS[id].unlocked = true;
    game.achievementPopups.push(new AchievementPopup(ACHIEVEMENTS[id]));
    saveData();
}

// Check achievements
function checkAchievements() {
    // First hit
    if (game.score > 0) unlockAchievement('firstBlood');

    // Combo achievements
    if (game.combo >= 5) unlockAchievement('combo5');
    if (game.combo >= 10) unlockAchievement('combo10');

    // Score achievements
    if (game.score >= 100) unlockAchievement('score100');
    if (game.score >= 500) unlockAchievement('score500');
    if (game.score >= 1000) unlockAchievement('score1000');

    // Red oni achievement
    if (game.redOniHits >= 5) unlockAchievement('redOni');
}

// Get combo multiplier
function getComboMultiplier() {
    if (game.combo < 3) return 1;
    if (game.combo < 5) return 1.5;
    if (game.combo < 10) return 2;
    return 3;
}

// Initialize game
function initGame() {
    game.score = 0;
    game.timeLeft = 10;
    game.beans = [];
    game.onis = [];
    game.clubs = [];
    game.particles = [];
    game.scorePopups = [];
    game.throwCooldown = 0;
    game.combo = 0;
    game.maxCombo = 0;
    game.comboTimer = 0;
    game.level = 1;
    game.redOniHits = 0;

    // Initialize player
    game.player.x = canvas.width / 2;
    game.player.y = canvas.height - 60;
    game.player.hp = game.player.maxHp;
    game.player.invincible = 0;

    // Reset input state
    game.keys = { up: false, down: false, left: false, right: false };
    game.joystick.active = false;

    // Spawn initial onis
    for (let i = 0; i < 3; i++) {
        game.onis.push(new Oni(1));
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

            // Level up every 3 seconds
            if (game.timeLeft === 7 || game.timeLeft === 4 || game.timeLeft === 1) {
                levelUp();
            }

            updateUI();
            if (game.timeLeft <= 0) {
                endGame();
            }
        }
    }, 1000);
}

// Level up - add more onis and increase speed
function levelUp() {
    game.level++;
    const speedMultiplier = 1 + (game.level - 1) * 0.3;

    // Add a new oni
    game.onis.push(new Oni(speedMultiplier));

    // Speed up existing onis
    game.onis.forEach(oni => {
        oni.vx *= 1.2;
        oni.vy *= 1.2;
    });
}

// End game
function endGame() {
    game.isPlaying = false;
    clearInterval(game.timerInterval);

    // Check perfect combo achievement
    if (game.combo >= 10) unlockAchievement('perfectCombo');

    // Update high score
    const isNewHighScore = game.score > game.highScore;
    if (isNewHighScore) {
        game.highScore = game.score;
        saveData();
    }

    // Update result screen
    document.getElementById('final-score').textContent = game.score;
    document.getElementById('high-score').textContent = `Best: ${game.highScore}`;
    document.getElementById('max-combo').textContent = `Max Combo: ${game.maxCombo}x`;

    // Show game over reason
    const gameOverReason = document.getElementById('game-over-reason');
    if (gameOverReason) {
        if (game.player.hp <= 0) {
            gameOverReason.textContent = 'You were knocked out!';
            gameOverReason.style.color = '#ff4444';
        } else {
            gameOverReason.textContent = 'Time Up!';
            gameOverReason.style.color = '#ffd700';
        }
    }

    if (isNewHighScore) {
        document.getElementById('new-record').classList.remove('hidden');
    } else {
        document.getElementById('new-record').classList.add('hidden');
    }

    document.getElementById('result-screen').classList.remove('hidden');
}

// Update UI
function updateUI() {
    document.getElementById('score').textContent = `Score: ${game.score}`;
    document.getElementById('timer').textContent = `Time: ${game.timeLeft}`;
    document.getElementById('combo').textContent = game.combo > 1 ? `${game.combo}x` : '';
    document.getElementById('level').textContent = `Lv.${game.level}`;
}

// Throw bean
function throwBean(targetX, targetY) {
    if (!game.isPlaying || game.throwCooldown > 0) return;

    // プレイヤーの位置から発射
    game.beans.push(new Bean(game.player.x, game.player.y - game.player.size, targetX, targetY));
    game.throwCooldown = 100; // ms between throws
}

// Update player position
function updatePlayer(dt) {
    let dx = 0;
    let dy = 0;

    // Keyboard input
    if (game.keys.left) dx -= 1;
    if (game.keys.right) dx += 1;
    if (game.keys.up) dy -= 1;
    if (game.keys.down) dy += 1;

    // Joystick input (mobile)
    if (game.joystick.active) {
        const jdx = game.joystick.currentX - game.joystick.startX;
        const jdy = game.joystick.currentY - game.joystick.startY;
        const jdist = Math.sqrt(jdx * jdx + jdy * jdy);
        if (jdist > 10) {
            dx = jdx / jdist;
            dy = jdy / jdist;
        }
    }

    // Normalize diagonal movement
    const len = Math.sqrt(dx * dx + dy * dy);
    if (len > 0) {
        dx /= len;
        dy /= len;
    }

    // Apply movement
    game.player.x += dx * game.player.speed * dt;
    game.player.y += dy * game.player.speed * dt;

    // Clamp to screen bounds
    const margin = game.player.size;
    game.player.x = Math.max(margin, Math.min(canvas.width - margin, game.player.x));
    game.player.y = Math.max(canvas.height * 0.5, Math.min(canvas.height - margin - 10, game.player.y));

    // Update invincibility timer
    if (game.player.invincible > 0) {
        game.player.invincible -= dt;
    }
}

// Damage player
function damagePlayer() {
    if (game.player.invincible > 0) return;

    game.player.hp--;
    game.player.invincible = 1.5; // 1.5秒の無敵時間

    // Create damage particles
    for (let i = 0; i < 10; i++) {
        game.particles.push(new Particle(game.player.x, game.player.y, '#ff0000'));
    }

    updateUI();

    // Game over if HP is 0
    if (game.player.hp <= 0) {
        endGame();
    }
}

// Check club collisions with player
function checkClubCollisions() {
    for (let club of game.clubs) {
        if (!club.alive) continue;

        const dx = club.x - game.player.x;
        const dy = club.y - game.player.y;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < club.size + game.player.size) {
            club.alive = false;
            damagePlayer();
        }
    }
}

// Check collisions
function checkCollisions() {
    // Bean vs Oni collisions
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

                // Combo system
                game.combo++;
                game.comboTimer = game.comboTimeout;
                if (game.combo > game.maxCombo) game.maxCombo = game.combo;

                // Calculate score with combo multiplier
                const multiplier = getComboMultiplier();
                const points = Math.floor(oni.points * multiplier);
                game.score += points;

                // Track red oni hits
                if (oni.color === '#ff4444') {
                    game.redOniHits++;
                }

                // Check achievements
                checkAchievements();

                updateUI();

                // Create particles
                const particleCount = game.combo >= 5 ? 20 : 10;
                for (let i = 0; i < particleCount; i++) {
                    game.particles.push(new Particle(bean.x, bean.y, oni.color));
                }

                // Create score popup with combo
                game.scorePopups.push(new ScorePopup(oni.x, oni.y - oni.size, points, game.combo));

                // Respawn oni at new position with current level speed
                const speedMultiplier = 1 + (game.level - 1) * 0.3;
                oni.x = Math.random() * (canvas.width - oni.size * 2) + oni.size;
                oni.y = Math.random() * (canvas.height - oni.size * 2 - 150) + oni.size + 50;
                oni.vx = (Math.random() - 0.5) * 3 * speedMultiplier;
                oni.vy = (Math.random() - 0.5) * 2 * speedMultiplier;

                break;
            }
        }
    }

    // Club vs Player collisions
    checkClubCollisions();
}

// Game loop
function gameLoop(timestamp) {
    if (!game.isPlaying) return;

    const dt = (timestamp - game.lastTime) / 1000;
    game.lastTime = timestamp;

    // Update cooldown
    game.throwCooldown = Math.max(0, game.throwCooldown - dt * 1000);

    // Update combo timer
    if (game.combo > 0) {
        game.comboTimer -= dt;
        if (game.comboTimer <= 0) {
            game.combo = 0;
            updateUI();
        }
    }

    // Update player
    updatePlayer(dt);

    // Auto-throw when holding
    if (game.isHolding && game.throwCooldown <= 0) {
        throwBean(game.targetX || canvas.width / 2, game.targetY || canvas.height / 2);
    }

    // Update entities
    game.onis.forEach(oni => oni.update(dt));
    game.beans.forEach(bean => bean.update());
    game.clubs.forEach(club => club.update());
    game.particles.forEach(p => p.update());
    game.scorePopups.forEach(p => p.update());
    game.achievementPopups.forEach(p => p.update(dt));

    // Check collisions
    checkCollisions();

    // Remove dead entities
    game.beans = game.beans.filter(b => b.alive);
    game.clubs = game.clubs.filter(c => c.alive);
    game.particles = game.particles.filter(p => p.life > 0);
    game.scorePopups = game.scorePopups.filter(p => p.life > 0);
    game.achievementPopups = game.achievementPopups.filter(p => p.life > 0);

    // Draw
    draw();

    requestAnimationFrame(gameLoop);
}

// Draw combo meter
function drawComboMeter() {
    if (game.combo < 2) return;

    const meterWidth = 100;
    const meterHeight = 8;
    const x = canvas.width - meterWidth - 10;
    const y = 35;

    // Background
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fillRect(x, y, meterWidth, meterHeight);

    // Fill based on combo timer
    const fillPercent = game.comboTimer / game.comboTimeout;
    const comboColor = game.combo >= 10 ? '#ff00ff' : game.combo >= 5 ? '#ff6b6b' : '#ffd700';
    ctx.fillStyle = comboColor;
    ctx.fillRect(x, y, meterWidth * fillPercent, meterHeight);

    // Border
    ctx.strokeStyle = 'white';
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, meterWidth, meterHeight);
}

// Draw player character
function drawPlayer() {
    ctx.save();

    // Flash when invincible
    if (game.player.invincible > 0) {
        ctx.globalAlpha = 0.5 + Math.sin(game.player.invincible * 20) * 0.5;
    }

    const px = game.player.x;
    const py = game.player.y;
    const size = game.player.size;

    // Body (simple human figure)
    ctx.fillStyle = '#FFE4C4'; // skin color
    ctx.beginPath();
    ctx.arc(px, py - size * 0.8, size * 0.6, 0, Math.PI * 2); // head
    ctx.fill();

    // Hair
    ctx.fillStyle = '#333';
    ctx.beginPath();
    ctx.arc(px, py - size * 1.0, size * 0.5, Math.PI, Math.PI * 2);
    ctx.fill();

    // Body
    ctx.fillStyle = '#4169E1';
    ctx.beginPath();
    ctx.ellipse(px, py, size * 0.5, size * 0.7, 0, 0, Math.PI * 2);
    ctx.fill();

    // Eyes
    ctx.fillStyle = 'black';
    ctx.beginPath();
    ctx.arc(px - size * 0.2, py - size * 0.85, 2, 0, Math.PI * 2);
    ctx.arc(px + size * 0.2, py - size * 0.85, 2, 0, Math.PI * 2);
    ctx.fill();

    ctx.restore();
}

// Draw HP hearts
function drawHP() {
    const heartSize = 20;
    const startX = 10;
    const startY = 50;

    for (let i = 0; i < game.player.maxHp; i++) {
        const x = startX + i * (heartSize + 5);

        if (i < game.player.hp) {
            // Full heart
            ctx.fillStyle = '#ff4444';
        } else {
            // Empty heart
            ctx.fillStyle = '#444';
        }

        // Draw heart shape
        ctx.beginPath();
        ctx.moveTo(x + heartSize / 2, startY + heartSize * 0.3);
        ctx.bezierCurveTo(x + heartSize / 2, startY, x, startY, x, startY + heartSize * 0.3);
        ctx.bezierCurveTo(x, startY + heartSize * 0.6, x + heartSize / 2, startY + heartSize, x + heartSize / 2, startY + heartSize);
        ctx.bezierCurveTo(x + heartSize / 2, startY + heartSize, x + heartSize, startY + heartSize * 0.6, x + heartSize, startY + heartSize * 0.3);
        ctx.bezierCurveTo(x + heartSize, startY, x + heartSize / 2, startY, x + heartSize / 2, startY + heartSize * 0.3);
        ctx.fill();
    }
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
    ctx.fillRect(0, canvas.height * 0.5, canvas.width, canvas.height * 0.5);

    // Draw entities
    game.onis.forEach(oni => oni.draw());
    game.clubs.forEach(club => club.draw());
    game.beans.forEach(bean => bean.draw());
    game.particles.forEach(p => p.draw());
    game.scorePopups.forEach(p => p.draw());

    // Draw player
    drawPlayer();

    // Draw HP
    drawHP();

    // Draw combo meter
    drawComboMeter();

    // Draw achievement popups
    game.achievementPopups.forEach(p => p.draw());
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
    if (!game.isPlaying) return;
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

// Touch events - left side for movement, right side for aiming/throwing
canvas.addEventListener('touchstart', (e) => {
    e.preventDefault();
    if (!game.isPlaying) return;

    for (let touch of e.changedTouches) {
        const rect = canvas.getBoundingClientRect();
        const scaleX = canvas.width / rect.width;
        const x = (touch.clientX - rect.left) * scaleX;
        const y = (touch.clientY - rect.top) * (canvas.height / rect.height);

        if (x < canvas.width / 2) {
            // Left side - joystick for movement
            game.joystick.active = true;
            game.joystick.startX = x;
            game.joystick.startY = y;
            game.joystick.currentX = x;
            game.joystick.currentY = y;
            game.joystick.touchId = touch.identifier;
        } else {
            // Right side - aim and throw
            game.isHolding = true;
            game.targetX = x;
            game.targetY = y;
            game.aimTouchId = touch.identifier;
            throwBean(x, y);
        }
    }
});

canvas.addEventListener('touchmove', (e) => {
    e.preventDefault();
    if (!game.isPlaying) return;

    for (let touch of e.changedTouches) {
        const rect = canvas.getBoundingClientRect();
        const scaleX = canvas.width / rect.width;
        const x = (touch.clientX - rect.left) * scaleX;
        const y = (touch.clientY - rect.top) * (canvas.height / rect.height);

        if (touch.identifier === game.joystick.touchId) {
            game.joystick.currentX = x;
            game.joystick.currentY = y;
        }
        if (touch.identifier === game.aimTouchId) {
            game.targetX = x;
            game.targetY = y;
        }
    }
});

canvas.addEventListener('touchend', (e) => {
    e.preventDefault();

    for (let touch of e.changedTouches) {
        if (touch.identifier === game.joystick.touchId) {
            game.joystick.active = false;
        }
        if (touch.identifier === game.aimTouchId) {
            game.isHolding = false;
        }
    }
});

// Keyboard events
document.addEventListener('keydown', (e) => {
    if (!game.isPlaying) return;

    // Movement keys
    if (e.code === 'KeyW' || e.code === 'ArrowUp') {
        game.keys.up = true;
        e.preventDefault();
    }
    if (e.code === 'KeyS' || e.code === 'ArrowDown') {
        game.keys.down = true;
        e.preventDefault();
    }
    if (e.code === 'KeyA' || e.code === 'ArrowLeft') {
        game.keys.left = true;
        e.preventDefault();
    }
    if (e.code === 'KeyD' || e.code === 'ArrowRight') {
        game.keys.right = true;
        e.preventDefault();
    }

    // Throw with space
    if (e.code === 'Space' && !e.repeat) {
        game.isHolding = true;
        // Throw towards mouse position or center
        throwBean(game.targetX || canvas.width / 2, game.targetY || 0);
        e.preventDefault();
    }
});

document.addEventListener('keyup', (e) => {
    // Movement keys
    if (e.code === 'KeyW' || e.code === 'ArrowUp') game.keys.up = false;
    if (e.code === 'KeyS' || e.code === 'ArrowDown') game.keys.down = false;
    if (e.code === 'KeyA' || e.code === 'ArrowLeft') game.keys.left = false;
    if (e.code === 'KeyD' || e.code === 'ArrowRight') game.keys.right = false;

    if (e.code === 'Space') {
        game.isHolding = false;
    }
});

// Button events
document.getElementById('start-btn').addEventListener('click', startGame);
document.getElementById('retry-btn').addEventListener('click', startGame);

// Update high score display on start screen
document.getElementById('best-score').textContent = game.highScore > 0 ? `Best: ${game.highScore}` : '';

// Initial draw
draw();
