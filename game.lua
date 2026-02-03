-- ============================================================
-- GAME FRAMEWORK - LUA SIDE
-- ============================================================
-- This framework provides all systems needed for a game
-- built on the C WebGL engine.
-- ============================================================

-- ============================================================
-- 1. VECTOR UTILITIES
-- ============================================================

local vec2 = {}
vec2.__index = vec2

function vec2.new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, vec2)
end

function vec2:clone()
    return vec2.new(self.x, self.y)
end

function vec2:add(other)
    return vec2.new(self.x + other.x, self.y + other.y)
end

function vec2:sub(other)
    return vec2.new(self.x - other.x, self.y - other.y)
end

function vec2:mul(scalar)
    return vec2.new(self.x * scalar, self.y * scalar)
end

function vec2:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function vec2:normalize()
    local len = self:length()
    if len == 0 then return vec2.new(0, 0) end
    return vec2.new(self.x / len, self.y / len)
end

function vec2:distance(other)
    return (self - other):length()
end

function vec2:dot(other)
    return self.x * other.x + self.y * other.y
end

function vec2.__add(a, b)
    return a:add(b)
end

function vec2.__sub(a, b)
    return a:sub(b)
end

function vec2.__mul(a, b)
    if type(a) == "number" then return b:mul(a) end
    if type(b) == "number" then return a:mul(b) end
end

-- ============================================================
-- 2. CLASS SYSTEM
-- ============================================================

local class = {}

function class.new(name, parent)
    local cls = {}
    cls.__name = name
    cls.__parent = parent
    cls.__index = cls
    
    function cls.new(...)
        local instance = setmetatable({}, cls)
        if instance.init then
            instance:init(...)
        end
        return instance
    end
    
    return cls
end

-- ============================================================
-- 3. COMPONENT SYSTEM
-- ============================================================

local component = {}

component.TYPE_RECT = "rect"
component.TYPE_CIRCLE = "circle"
component.TYPE_SPRITE = "sprite"
component.TYPE_BUTTON = "button"
component.TYPE_LABEL = "label"
component.TYPE_PLAYER = "player"
component.TYPE_ENEMY = "enemy"
component.TYPE_POPUP = "popup"
component.TYPE_MENU = "menu"

local Component = class.new("Component")

function Component:init(compType, props)
    self.type = compType
    self.x = props.x or 0
    self.y = props.y or 0
    self.width = props.width or 0
    self.height = props.height or 0
    self.rotation = props.rotation or 0
    self.scaleX = props.scaleX or 1
    self.scaleY = props.scaleY or 1
    self.visible = props.visible ~= false
    self.color = props.color or {r = 1, g = 1, b = 1, a = 1}
    self.props = props
    self.children = {}
    self.parent = nil
    self.active = true
end

function Component:setPosition(x, y)
    self.x = x
    self.y = y
end

function Component:getPosition()
    return self.x, self.y
end

function Component:addChild(child)
    table.insert(self.children, child)
    child.parent = self
    return child
end

function Component:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            break
        end
    end
end

function Component:destroy()
    self.active = false
    for _, child in ipairs(self.children) do
        child:destroy()
    end
end

function Component:update(dt)
    -- Override in subclasses
    for _, child in ipairs(self.children) do
        if child.active then
            child:update(dt)
        end
    end
end

function Component:draw()
    if not self.visible then return end
    
    if self.type == component.TYPE_RECT then
        draw.rect(self.x, self.y, self.width, self.height, 
                  self.color.r, self.color.g, self.color.b, self.color.a)
    elseif self.type == component.TYPE_CIRCLE then
        draw.circle(self.x, self.y, self.width, 
                    self.color.r, self.color.g, self.color.b, self.color.a)
    elseif self.type == component.TYPE_LABEL then
        draw.text(self.props.text or "Label", self.x, self.y)
    end
    
    for _, child in ipairs(self.children) do
        if child.active then
            child:draw()
        end
    end
end

component.Component = Component

function component.newRect(props)
    return Component.new(component.TYPE_RECT, props)
end

function component.newCircle(props)
    return Component.new(component.TYPE_CIRCLE, props)
end

function component.newSprite(props)
    return Component.new(component.TYPE_SPRITE, props)
end

function component.newButton(props)
    return Component.new(component.TYPE_BUTTON, props)
end

function component.newLabel(props)
    return Component.new(component.TYPE_LABEL, props)
end

function component.newPlayer(props)
    return Component.new(component.TYPE_PLAYER, props)
end

function component.newEnemy(props)
    return Component.new(component.TYPE_ENEMY, props)
end

-- ============================================================
-- 4. ANIMATION SYSTEM
-- ============================================================

local Animation = class.new("Animation")

function Animation:init(duration, callback)
    self.duration = duration or 1.0
    self.elapsed = 0
    self.callback = callback
    self.loop = false
    self.running = true
end

function Animation:update(dt)
    if not self.running then return end
    
    self.elapsed = self.elapsed + dt
    
    if self.elapsed >= self.duration then
        self.elapsed = self.duration
        if self.callback then
            self.callback(1.0)
        end
        if self.loop then
            self.elapsed = 0
        else
            self.running = false
        end
    else
        if self.callback then
            self.callback(self.elapsed / self.duration)
        end
    end
end

function Animation:setLoop(loop)
    self.loop = loop
    return self
end

function Animation:stop()
    self.running = false
end

function Animation:reset()
    self.elapsed = 0
    self.running = true
end

local animation = {}

function animation.create(duration, callback)
    return Animation.new(duration, callback)
end

-- ============================================================
-- 5. TIMER SYSTEM
-- ============================================================

local Timer = class.new("Timer")

function Timer:init(duration, callback)
    self.duration = duration
    self.elapsed = 0
    self.callback = callback
    self.finished = false
end

function Timer:update(dt)
    if self.finished then return end
    
    self.elapsed = self.elapsed + dt
    if self.elapsed >= self.duration then
        self.finished = true
        if self.callback then
            self.callback()
        end
    end
end

function Timer:isFinished()
    return self.finished
end

function Timer:reset()
    self.elapsed = 0
    self.finished = false
end

local timer = {}

function timer.create(duration, callback)
    return Timer.new(duration, callback)
end

-- ============================================================
-- 6. GAMESTATE MANAGER
-- ============================================================

local GameState = class.new("GameState")

function GameState:init()
    self.states = {}
    self.currentState = nil
end

function GameState:register(name, state)
    self.states[name] = state
end

function GameState:enter(name)
    if self.currentState then
        if self.currentState.exit then
            self.currentState:exit()
        end
    end
    
    self.currentState = self.states[name]
    if self.currentState and self.currentState.enter then
        self.currentState:enter()
    end
end

function GameState:update(dt)
    if self.currentState and self.currentState.update then
        self.currentState:update(dt)
    end
end

function GameState:draw()
    if self.currentState and self.currentState.draw then
        self.currentState:draw()
    end
end

local gameState = GameState.new()

-- ============================================================
-- 7. COLLISION SYSTEM
-- ============================================================

local collision = {}

function collision.pointRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

function collision.pointCircle(px, py, cx, cy, radius)
    local dx = px - cx
    local dy = py - cy
    return (dx * dx + dy * dy) <= (radius * radius)
end

function collision.rectRect(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and
           y1 < y2 + h2 and y1 + h1 > y2
end

function collision.circleCircle(x1, y1, r1, x2, y2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < r1 + r2
end

-- ============================================================
-- 8. PARTICLE SYSTEM
-- ============================================================

local Particle = class.new("Particle")

function Particle:init(x, y, vx, vy, lifetime, color)
    self.x = x
    self.y = y
    self.vx = vx or 0
    self.vy = vy or 0
    self.lifetime = lifetime or 1.0
    self.elapsed = 0
    self.color = color or {r = 1, g = 1, b = 1, a = 1}
    self.alive = true
end

function Particle:update(dt)
    self.elapsed = self.elapsed + dt
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    if self.elapsed >= self.lifetime then
        self.alive = false
    end
end

function Particle:draw()
    draw.circle(self.x, self.y, 3, self.color.r, self.color.g, self.color.b, self.color.a)
end

local ParticleEmitter = class.new("ParticleEmitter")

function ParticleEmitter:init(x, y)
    self.x = x
    self.y = y
    self.particles = {}
    self.emitting = false
end

function ParticleEmitter:emit(count, vx, vy, lifetime, color)
    for i = 1, count do
        local particle = Particle.new(
            self.x + math.random(-10, 10),
            self.y + math.random(-10, 10),
            vx + math.random(-50, 50) / 50,
            vy + math.random(-50, 50) / 50,
            lifetime,
            color
        )
        table.insert(self.particles, particle)
    end
end

function ParticleEmitter:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p:update(dt)
        if not p.alive then
            table.remove(self.particles, i)
        end
    end
end

function ParticleEmitter:draw()
    for _, p in ipairs(self.particles) do
        p:draw()
    end
end

local particle = {}

function particle.newEmitter(x, y)
    return ParticleEmitter.new(x, y)
end

-- ============================================================
-- 9. SIGNAL/EVENT DISPATCHER
-- ============================================================

local Signal = class.new("Signal")

function Signal:init(name)
    self.name = name
    self.listeners = {}
end

function Signal:connect(callback)
    table.insert(self.listeners, callback)
end

function Signal:disconnect(callback)
    for i, cb in ipairs(self.listeners) do
        if cb == callback then
            table.remove(self.listeners, i)
            break
        end
    end
end

function Signal:emit(...)
    for _, callback in ipairs(self.listeners) do
        callback(...)
    end
end

local signal = {}

function signal.new(name)
    return Signal.new(name)
end

-- ============================================================
-- 10. CAMERA SYSTEM
-- ============================================================

local Camera = class.new("Camera")

function Camera:init(x, y, width, height)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 800
    self.height = height or 600
    self.zoom = 1.0
end

function Camera:setPosition(x, y)
    self.x = x
    self.y = y
end

function Camera:setZoom(zoom)
    self.zoom = zoom
end

function Camera:worldToScreen(wx, wy)
    return (wx - self.x) * self.zoom, (wy - self.y) * self.zoom
end

function Camera:screenToWorld(sx, sy)
    return sx / self.zoom + self.x, sy / self.zoom + self.y
end

local camera = Camera.new(0, 0, 800, 600)

-- ============================================================
-- 11. AI SYSTEM
-- ============================================================

local AI = class.new("AI")

function AI:init(owner)
    self.owner = owner
    self.state = "idle"
    self.targetX = 0
    self.targetY = 0
    self.speed = 50
end

function AI:setState(newState)
    self.state = newState
end

function AI:setTarget(x, y)
    self.targetX = x
    self.targetY = y
end

function AI:update(dt)
    if self.state == "chase" then
        local dx = self.targetX - self.owner.x
        local dy = self.targetY - self.owner.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist > 0 then
            self.owner.x = self.owner.x + (dx / dist) * self.speed * dt
            self.owner.y = self.owner.y + (dy / dist) * self.speed * dt
        end
    end
end

local ai = {}

function ai.newAI(owner)
    return AI.new(owner)
end

-- ============================================================
-- 12. DIALOGUE SYSTEM
-- ============================================================

local Dialogue = class.new("Dialogue")

function Dialogue:init(lines)
    self.lines = lines or {}
    self.current = 1
    self.finished = false
end

function Dialogue:next()
    self.current = self.current + 1
    if self.current > #self.lines then
        self.finished = true
        self.current = #self.lines
    end
end

function Dialogue:getCurrentLine()
    return self.lines[self.current]
end

function Dialogue:isFinished()
    return self.finished
end

function Dialogue:reset()
    self.current = 1
    self.finished = false
end

local dialogue = {}

function dialogue.new(lines)
    return Dialogue.new(lines)
end

-- ============================================================
-- MAIN GAME FRAMEWORK INITIALIZATION
-- ============================================================

-- Global component registry
local components = {}

-- ============================================================
-- INIT - Called once at startup
-- ============================================================

function init()
    print("[ENGINE] Game Framework Initialized!")
    
    -- Create example components
    
    -- Player component
    local player = component.newRect({
        x = 100,
        y = 100,
        width = 30,
        height = 30,
        color = {r = 0.2, g = 0.8, b = 0.2, a = 1}
    })
    table.insert(components, player)
    
    -- Enemy component
    local enemy = component.newCircle({
        x = 500,
        y = 300,
        width = 20,
        color = {r = 1, g = 0.2, b = 0.2, a = 1}
    })
    table.insert(components, enemy)
    
    -- UI Label
    local label = component.newLabel({
        x = 10,
        y = 10,
        text = "Game Framework - Press arrow keys to move",
        color = {r = 1, g = 1, b = 1, a = 1}
    })
    table.insert(components, label)
    
    -- Particle emitter
    local emitter = particle.newEmitter(640, 360)
    table.insert(components, {
        type = "emitter",
        emitter = emitter,
        update = function(self, dt) self.emitter:update(dt) end,
        draw = function(self) self.emitter:draw() end
    })
    
    -- Animation example
    local animRotation = 0
    local rotAnim = animation.create(2.0, function(progress)
        animRotation = progress * 360
    end):setLoop(true):reset()
    table.insert(components, {
        type = "animation",
        anim = rotAnim,
        update = function(self, dt) self.anim:update(dt) end,
        draw = function(self) end
    })
    
    -- Store for later reference
    _G.player = player
    _G.enemy = enemy
    _G.emitter = emitter
    _G.animRotation = animRotation
end

-- ============================================================
-- LOOP - Called every frame with dt (delta time)
-- ============================================================

function loop(dt)
    -- Update all components
    for _, comp in ipairs(components) do
        if comp.active ~= false and comp.update then
            comp:update(dt)
        end
    end
    
    -- Handle input
    local player = _G.player
    if keyboard.isDown("w") then
        player.y = player.y - 200 * dt
    end
    if keyboard.isDown("s") then
        player.y = player.y + 200 * dt
    end
    if keyboard.isDown("a") then
        player.x = player.x - 200 * dt
    end
    if keyboard.isDown("d") then
        player.x = player.x + 200 * dt
    end
    
    -- Simple collision check
    local enemy = _G.enemy
    if collision.rectRect(player.x, player.y, player.width, player.height,
                          enemy.x - enemy.width, enemy.y - enemy.width, 
                          enemy.width * 2, enemy.width * 2) then
        -- Emit particles on collision
        _G.emitter:emit(10, 0, 0, 0.5, {r = 1, g = 1, b = 0, a = 1})
        
        -- Move enemy away
        enemy.x = math.random(100, 1000)
        enemy.y = math.random(100, 600)
    end
    
    -- Update animation
    _G.animRotation = _G.animRotation or 0
end

-- ============================================================
-- WINDOW - Called every frame to render
-- ============================================================

function window()
    -- Clear and set background
    graphics.setClearColor(0.05, 0.05, 0.1)
    
    -- Draw all components
    for _, comp in ipairs(components) do
        if comp.active ~= false and comp.draw then
            comp:draw()
        end
    end
    
    -- Draw debug info
    local winSize = graphics.getWindowSize()
    draw.text("FPS: ~60 | Components: " .. #components, 10, 30)
end