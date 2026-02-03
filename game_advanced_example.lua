-- ============================================================
-- ADVANCED GAME EXAMPLE
-- Shows advanced features of the game framework
-- ============================================================

-- ============================================================
-- EXAMPLE: SPACE SHOOTER GAME
-- ============================================================

local GameScene = class.new("GameScene")

function GameScene:init()
    self.player = nil
    self.enemies = {}
    self.bullets = {}
    self.score = 0
    self.wave = 1
    self.waveTimer = nil
end

function GameScene:enter()
    print("Entering Game Scene - Wave " .. self.wave)
    
    -- Create player
    self.player = {
        comp = component.newRect({
            x = 640, y = 550,
            width = 30, height = 30,
            color = {r = 0.2, g = 0.8, b = 0.2, a = 1}
        }),
        speed = 300,
        health = 100
    }
    
    -- Spawn first enemies
    self:spawnWave()
end

function GameScene:spawnWave()
    for i = 1, 5 + self.wave do
        local enemy = {
            comp = component.newCircle({
                x = math.random(100, 1100),
                y = math.random(50, 200),
                width = 15,
                color = {r = 1, g = 0.2, b = 0.2, a = 1}
            }),
            vx = math.random(-100, 100),
            vy = math.random(50, 100),
            health = 10,
            ai = nil
        }
        
        enemy.ai = ai.newAI(enemy.comp)
        enemy.ai:setState("move")
        
        table.insert(self.enemies, enemy)
    end
end

function GameScene:update(dt)
    -- Update player
    if keyboard.isDown("a") then
        self.player.comp.x = self.player.comp.x - self.player.speed * dt
    end
    if keyboard.isDown("d") then
        self.player.comp.x = self.player.comp.x + self.player.speed * dt
    end
    
    -- Clamp player position
    if self.player.comp.x < 0 then self.player.comp.x = 0 end
    if self.player.comp.x > 1250 then self.player.comp.x = 1250 end
    
    -- Shooting
    if keyboard.isDown("space") then
        self:shoot()
    end
    
    -- Update bullets
    for i = #self.bullets, 1, -1 do
        local bullet = self.bullets[i]
        bullet.y = bullet.y - 500 * dt
        
        -- Remove off-screen bullets
        if bullet.y < 0 then
            table.remove(self.bullets, i)
        end
    end
    
    -- Update enemies
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        
        -- Simple movement
        enemy.comp.y = enemy.comp.y + enemy.vy * dt
        
        -- Remove off-screen enemies
        if enemy.comp.y > 720 then
            table.remove(self.enemies, i)
            self.score = self.score + 100
        else
            -- Check collision with bullets
            for j = #self.bullets, 1, -1 do
                local bullet = self.bullets[j]
                
                if collision.pointCircle(bullet.x, bullet.y,
                                        enemy.comp.x, enemy.comp.y,
                                        enemy.comp.width) then
                    enemy.health = enemy.health - 10
                    table.remove(self.bullets, j)
                    
                    if enemy.health <= 0 then
                        table.remove(self.enemies, i)
                        self.score = self.score + 50
                        break
                    end
                end
            end
        end
    end
    
    -- Spawn next wave
    if #self.enemies == 0 then
        self.wave = self.wave + 1
        self:spawnWave()
    end
end

function GameScene:shoot()
    if not self.lastShot or (love.timer.getTime() - self.lastShot) > 0.1 then
        table.insert(self.bullets, {
            x = self.player.comp.x + 15,
            y = self.player.comp.y
        })
        self.lastShot = 0 -- Simplified timer
    end
end

function GameScene:draw()
    -- Draw player
    draw.rect(self.player.comp.x, self.player.comp.y,
              self.player.comp.width, self.player.comp.height,
              0.2, 0.8, 0.2, 1)
    
    -- Draw enemies
    for _, enemy in ipairs(self.enemies) do
        draw.circle(enemy.comp.x, enemy.comp.y,
                   enemy.comp.width,
                   1, 0.2, 0.2, 1)
    end
    
    -- Draw bullets
    for _, bullet in ipairs(self.bullets) do
        draw.circle(bullet.x, bullet.y, 5,
                   1, 1, 0, 1)
    end
    
    -- Draw UI
    draw.text("Score: " .. self.score, 10, 10)
    draw.text("Wave: " .. self.wave, 10, 30)
    draw.text("Enemies: " .. #self.enemies, 10, 50)
end

function GameScene:exit()
    print("Leaving Game Scene")
end

-- ============================================================
-- MAIN FRAMEWORK FUNCTIONS
-- ============================================================

function init()
    print("[GAME] Advanced Example Initialized!")
    
    -- Initialize game state manager
    gameState:register("game", GameScene.new())
    gameState:enter("game")
end

function loop(dt)
    gameState:update(dt)
end

function window()
    graphics.setClearColor(0.05, 0.05, 0.1)
    gameState:draw()
end