# Game Framework - C + WebGL + Lua

A complete game framework that combines **C** with **WebGL rendering** and **Lua** for gameplay logic. This framework provides a modular, extensible system for building 2D games.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    C Engine (engine.c)                  │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         OpenGL/WebGL Rendering Layer          │    │
│  │  • Shader management                          │    │
│  │  • Geometry rendering (rect, circle, line)    │    │
│  │  • Matrix transformations                     │    │
│  └────────────────────────────────────────────────┘    │
│                          ▲                              │
│                          │                              │
│  ┌────────────────────────────────────────────────┐    │
│  │         Lua Interpreter Integration           │    │
│  │  • Loads and executes game.lua                │    │
│  │  • Exposes C functions to Lua                 │    │
│  │  • Calls init(), loop(dt), window()           │    │
│  └────────────────────────────────────────────────┘    │
│                          ▲                              │
│                          │                              │
│          Main Loop: glfwPollEvents() → render          │
└─────────────────────────────────────────────────────────┘
          │
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│               Lua Game Framework (game.lua)             │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │  Core Systems                                │      │
│  │  • Component system                          │      │
│  │  • Animation system                          │      │
│  │  • Timer/event system                        │      │
│  │  • Collision detection                       │      │
│  │  • Particle emitter                          │      │
│  │  • AI system                                 │      │
│  │  • Dialogue system                           │      │
│  │  • Camera system                             │      │
│  │  • GameState manager                         │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │  Exposed to Game Code                        │      │
│  │  • init() - Initialize game                  │      │
│  │  • loop(dt) - Update game state              │      │
│  │  • window() - Render everything              │      │
│  └──────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

## Features

### C Engine Features
- ✅ Real graphical window using GLFW
- ✅ WebGL 2.0 rendering pipeline
- ✅ Shader compilation and management
- ✅ Embedded Lua interpreter
- ✅ Input handling (keyboard, mouse, controller)
- ✅ Main loop with delta time computation
- ✅ Emscripten support for web deployment

### Lua Framework Features
- ✅ **Component System**: Flexible entity-component architecture
- ✅ **Animation System**: Procedural and tween-based animations
- ✅ **Vector Math**: 2D vector utilities with operator overloading
- ✅ **Collision Detection**: Rectangle, circle, and point collision tests
- ✅ **Particle System**: Fully functional particle emitter
- ✅ **Timer System**: Delayed callbacks and timing
- ✅ **AI System**: Simple pathfinding and state machine
- ✅ **Event System**: Signal/event dispatching
- ✅ **Camera System**: View transformation and zoom
- ✅ **GameState Manager**: State machine for game scenes
- ✅ **Dialogue System**: Dialogue and scripting support

## Building

### Prerequisites
- CMake 3.10+
- C compiler (GCC, Clang, MSVC)
- GLFW 3
- OpenGL development libraries
- Lua 5.4+

### Native Build (Desktop)

```bash
# Create build directory
mkdir build
cd build

# Configure with CMake
cmake ..

# Build
cmake --build .

# Run
./game
```

### Web Build (Emscripten)

```bash
# Install Emscripten (https://emscripten.org/docs/getting_started/downloads.html)

# Build for web
emcmake cmake ..
cmake --build .

# Serve with web server
python3 -m http.server 8000

# Visit http://localhost:8000/game.html
```

## Usage Guide

### 1. Creating Components

Components are the fundamental building blocks. Create them in `init()`:

```lua
-- Create a rectangle component
local player = component.newRect({
    x = 100,
    y = 100,
    width = 30,
    height = 30,
    color = {r = 0.2, g = 0.8, b = 0.2, a = 1}
})

-- Create a circle component
local enemy = component.newCircle({
    x = 500,
    y = 300,
    width = 20,
    color = {r = 1, g = 0.2, b = 0.2, a = 1}
})

table.insert(components, player)
table.insert(components, enemy)
```

### 2. Handling Input

Input is checked in `loop(dt)`:

```lua
function loop(dt)
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
    
    -- Check mouse
    local mx = mouse.x()
    local my = mouse.y()
end
```

### 3. Using Animations

Create and manage animations:

```lua
local animation = animation.create(2.0, function(progress)
    -- progress goes from 0 to 1 over 2 seconds
    player.x = 100 + progress * 100
    player.rotation = progress * 360
end):setLoop(true)

-- In loop(dt):
animation:update(dt)
```

### 4. Collision Detection

Use the collision system:

```lua
if collision.rectRect(player.x, player.y, player.width, player.height,
                      enemy.x - enemy.width, enemy.y - enemy.width,
                      enemy.width * 2, enemy.width * 2) then
    print("Collision detected!")
end
```

### 5. Particle Effects

Create particle emitters:

```lua
local emitter = particle.newEmitter(640, 360)

-- In loop(dt):
emitter:emit(10, 0, -100, 1.0, {r = 1, g = 1, b = 0, a = 1})

-- In window():
emitter:draw()
```

### 6. AI Behavior

Simple AI system with state management:

```lua
local enemy_ai = ai.newAI(enemy)
enemy_ai:setState("chase")
enemy_ai:setTarget(player.x, player.y)

-- In loop(dt):
enemy_ai:update(dt)
```

### 7. Timers and Events

Delayed callbacks:

```lua
local t = timer.create(3.0, function()
    print("3 seconds have passed!")
end)

-- In loop(dt):
t:update(dt)
```

### 8. Signals/Events

Event dispatching system:

```lua
local onPlayerDeath = signal.new("player_death")
onPlayerDeath:connect(function()
    print("Player died!")
end)

-- Later:
onPlayerDeath:emit()
```

## API Reference

### Drawing Functions

```lua
draw.rect(x, y, width, height, r, g, b, [a])
draw.circle(x, y, radius, r, g, b, [a])
draw.line(x1, y1, x2, y2, r, g, b, [a])
draw.text(text, x, y)
```

### Input Functions

```lua
keyboard.isDown(key)        -- "w", "a", "s", "d", "space", "escape", etc.
mouse.x()                   -- Get mouse X position
mouse.y()                   -- Get mouse Y position
```

### Graphics Functions

```lua
graphics.setClearColor(r, g, b)
graphics.getWindowSize()    -- Returns {width, height}
```

### Components

```lua
component.newRect(props)
component.newCircle(props)
component.newSprite(props)
component.newButton(props)
component.newLabel(props)
component.newPlayer(props)
component.newEnemy(props)
```

### Vector Math

```lua
local v1 = vec2.new(10, 20)
local v2 = vec2.new(5, 10)

v1 + v2
v1 - v2
v1 * 2
v1:length()
v1:normalize()
v1:distance(v2)
v1:dot(v2)
```

### Animation

```lua
local anim = animation.create(duration, callback)
anim:setLoop(true)
anim:update(dt)
anim:stop()
anim:reset()
```

### Timer

```lua
local t = timer.create(duration, callback)
t:update(dt)
t:isFinished()
t:reset()
```

### Collision

```lua
collision.pointRect(px, py, rx, ry, rw, rh)
collision.pointCircle(px, py, cx, cy, radius)
collision.rectRect(x1, y1, w1, h1, x2, y2, w2, h2)
collision.circleCircle(x1, y1, r1, x2, y2, r2)
```

### Particle System

```lua
local emitter = particle.newEmitter(x, y)
emitter:emit(count, vx, vy, lifetime, color)
emitter:update(dt)
emitter:draw()
```

### AI System

```lua
local ai = ai.newAI(owner)
ai:setState(newState)
ai:setTarget(x, y)
ai:update(dt)
```

### Camera

```lua
camera:setPosition(x, y)
camera:setZoom(zoom)
camera:worldToScreen(wx, wy)
camera:screenToWorld(sx, sy)
```

## Example Game Flow

```lua
function init()
    -- Create all game entities
    _G.player = component.newRect({x = 100, y = 100, width = 30, height = 30})
    _G.enemies = {}
    table.insert(_G.enemies, component.newCircle({x = 500, y = 300, width = 20}))
end

function loop(dt)
    -- Update game logic
    local player = _G.player
    
    -- Handle input
    if keyboard.isDown("w") then player.y = player.y - 200 * dt end
    if keyboard.isDown("s") then player.y = player.y + 200 * dt end
    if keyboard.isDown("a") then player.x = player.x - 200 * dt end
    if keyboard.isDown("d") then player.x = player.x + 200 * dt end
    
    -- Update enemies
    for _, enemy in ipairs(_G.enemies) do
        -- AI logic here
    end
end

function window()
    -- Render everything
    _G.player:draw()
    for _, enemy in ipairs(_G.enemies) do
        enemy:draw()
    end
end
```

## File Structure

```
game-framework/
├── engine.c              # C engine with WebGL rendering
├── game.lua              # Lua game framework
├── CMakeLists.txt        # Build configuration
├── README.md             # This file
├── Makefile              # Alternative build
└── build/                # Build output directory
    └── game              # Compiled executable
```

## Extending the Framework

### Adding a New Component Type

```lua
function component.newCustom(props)
    return Component.new("custom", props)
end
```

### Adding a New System

```lua
local MySystem = class.new("MySystem")

function MySystem:init()
    -- Initialize
end

function MySystem:update(dt)
    -- Update
end

local mySystem = MySystem.new()
```

### Custom Rendering

```lua
function window()
    -- Custom rendering code
    draw.rect(0, 0, 100, 100, 1, 0, 0, 1)
    draw.circle(640, 360, 50, 0, 1, 0, 1)
    draw.text("Custom Render", 10, 10)
end
```

## Performance Tips

1. **Reuse components** instead of creating/destroying frequently
2. **Use object pools** for particles and temporary entities
3. **Limit collision checks** - only check relevant pairs
4. **Batch draw calls** when possible
5. **Profile with browser DevTools** (web build)

## Troubleshooting

### "Failed to initialize GLFW"
- Install GLFW development libraries
- On Ubuntu: `sudo apt-get install libglfw3-dev`
- On macOS: `brew install glfw3`

### "Lua error: attempt to index nil"
- Ensure all components are created in `init()`
- Check that global references are set correctly

### Web build shows blank page
- Check browser console for errors
- Ensure game.lua is properly embedded
- Verify WebGL context is created

### Performance issues
- Reduce particle count
- Use smaller collision detection grid
- Profile with browser DevTools
- Enable compile optimizations: `-O3`

## License

MIT License - Feel free to use this framework for any project!

## Contributing

Contributions welcome! Please feel free to submit PRs for:
- New component types
- Additional systems
- Performance improvements
- Bug fixes
- Documentation improvements

## Road map

- [ ] Sound system (Web Audio API)
- [ ] Font rendering system
- [ ] Sprite sheet animation
- [ ] Physics engine integration
- [ ] Network support
- [ ] Save/load system
- [ ] Visual editor
- [ ] Debugging tools

---

Happy game making! 🎮