#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/html5.h>
#define GLFW_INCLUDE_ES2
#else
#include <GLFW/glfw3.h>
#endif

#include <GL/gl.h>
#include <GL/glext.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/* ============================================================ */
/* GLOBAL STATE */
/* ============================================================ */

typedef struct {
    GLFWwindow* window;
    lua_State* L;
    double lastTime;
    float windowWidth;
    float windowHeight;
    int running;
    GLuint shaderProgram;
    GLuint VAO, VBO;
} EngineState;

static EngineState g_engine = {0};

/* ============================================================ */
/* SHADER UTILITIES */
/* ============================================================ */

const char* vertexShaderSource = "#version 100\n"
    "attribute vec2 position;\n"
    "attribute vec4 color;\n"
    "varying vec4 fragColor;\n"
    "uniform mat4 projection;\n"
    "void main() {\n"
    "   gl_Position = projection * vec4(position, 0.0, 1.0);\n"
    "   fragColor = color;\n"
    "}\n";

const char* fragmentShaderSource = "#version 100\n"
    "precision mediump float;\n"
    "varying vec4 fragColor;\n"
    "void main() {\n"
    "   gl_FragColor = fragColor;\n"
    "}\n";

GLuint compileShader(const char* source, GLenum type) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    
    int success;
    char infoLog[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        fprintf(stderr, "Shader compilation failed: %s\n", infoLog);
    }
    return shader;
}

GLuint createShaderProgram() {
    GLuint vertexShader = compileShader(vertexShaderSource, GL_VERTEX_SHADER);
    GLuint fragmentShader = compileShader(fragmentShaderSource, GL_FRAGMENT_SHADER);
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    int success;
    char infoLog[512];
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(program, 512, NULL, infoLog);
        fprintf(stderr, "Shader program linking failed: %s\n", infoLog);
    }
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return program;
}

/* ============================================================ */
/* MATRIX UTILITIES */
/* ============================================================ */

void orthographicMatrix(float* matrix, float left, float right, float bottom, float top) {
    memset(matrix, 0, 16 * sizeof(float));
    
    matrix[0] = 2.0f / (right - left);
    matrix[5] = 2.0f / (top - bottom);
    matrix[10] = -1.0f;
    matrix[12] = -(right + left) / (right - left);
    matrix[13] = -(top + bottom) / (top - bottom);
    matrix[15] = 1.0f;
}

/* ============================================================ */
/* LUA BINDING FUNCTIONS */
/* ============================================================ */

static int lua_drawRect(lua_State* L) {
    float x = luaL_checknumber(L, 1);
    float y = luaL_checknumber(L, 2);
    float w = luaL_checknumber(L, 3);
    float h = luaL_checknumber(L, 4);
    float r = luaL_checknumber(L, 5);
    float g = luaL_checknumber(L, 6);
    float b = luaL_checknumber(L, 7);
    float a = luaL_optnumber(L, 8, 1.0);
    
    float vertices[] = {
        x,     y,     r, g, b, a,
        x + w, y,     r, g, b, a,
        x + w, y + h, r, g, b, a,
        x,     y + h, r, g, b, a,
    };
    
    GLuint VAO, VBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(2 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    glUseProgram(g_engine.shaderProgram);
    
    float projection[16];
    orthographicMatrix(projection, 0, g_engine.windowWidth, g_engine.windowHeight, 0);
    
    GLint projLoc = glGetUniformLocation(g_engine.shaderProgram, "projection");
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, projection);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glDeleteBuffers(1, &VBO);
    glDeleteVertexArrays(1, &VAO);
    
    return 0;
}

static int lua_drawCircle(lua_State* L) {
    float x = luaL_checknumber(L, 1);
    float y = luaL_checknumber(L, 2);
    float radius = luaL_checknumber(L, 3);
    float r = luaL_checknumber(L, 4);
    float g = luaL_checknumber(L, 5);
    float b = luaL_checknumber(L, 6);
    float a = luaL_optnumber(L, 7, 1.0);
    
    int segments = 32;
    float* vertices = malloc((segments + 2) * 6 * sizeof(float));
    
    vertices[0] = x;
    vertices[1] = y;
    vertices[2] = r;
    vertices[3] = g;
    vertices[4] = b;
    vertices[5] = a;
    
    for (int i = 0; i <= segments; i++) {
        float angle = 2.0f * 3.14159f * i / segments;
        float vx = x + radius * cosf(angle);
        float vy = y + radius * sinf(angle);
        
        vertices[(i + 1) * 6 + 0] = vx;
        vertices[(i + 1) * 6 + 1] = vy;
        vertices[(i + 1) * 6 + 2] = r;
        vertices[(i + 1) * 6 + 3] = g;
        vertices[(i + 1) * 6 + 4] = b;
        vertices[(i + 1) * 6 + 5] = a;
    }
    
    GLuint VAO, VBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, (segments + 2) * 6 * sizeof(float), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(2 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    glUseProgram(g_engine.shaderProgram);
    
    float projection[16];
    orthographicMatrix(projection, 0, g_engine.windowWidth, g_engine.windowHeight, 0);
    
    GLint projLoc = glGetUniformLocation(g_engine.shaderProgram, "projection");
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, projection);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, segments + 2);
    
    glDeleteBuffers(1, &VBO);
    glDeleteVertexArrays(1, &VAO);
    free(vertices);
    
    return 0;
}

static int lua_drawLine(lua_State* L) {
    float x1 = luaL_checknumber(L, 1);
    float y1 = luaL_checknumber(L, 2);
    float x2 = luaL_checknumber(L, 3);
    float y2 = luaL_checknumber(L, 4);
    float r = luaL_checknumber(L, 5);
    float g = luaL_checknumber(L, 6);
    float b = luaL_checknumber(L, 7);
    float a = luaL_optnumber(L, 8, 1.0);
    
    float vertices[] = {
        x1, y1, r, g, b, a,
        x2, y2, r, g, b, a,
    };
    
    GLuint VAO, VBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(2 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    glUseProgram(g_engine.shaderProgram);
    
    float projection[16];
    orthographicMatrix(projection, 0, g_engine.windowWidth, g_engine.windowHeight, 0);
    
    GLint projLoc = glGetUniformLocation(g_engine.shaderProgram, "projection");
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, projection);
    
    glDrawArrays(GL_LINE_LOOP, 0, 2);
    
    glDeleteBuffers(1, &VBO);
    glDeleteVertexArrays(1, &VAO);
    
    return 0;
}

static int lua_drawText(lua_State* L) {
    const char* text = luaL_checkstring(L, 1);
    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);
    
    /* Stub: Text rendering would require a font atlas system */
    printf("[TEXT] %s at (%.1f, %.1f)\n", text, x, y);
    
    return 0;
}

static int lua_keyDown(lua_State* L) {
    const char* key = luaL_checkstring(L, 1);
    int keyCode = GLFW_KEY_SPACE;
    
    if (strcmp(key, "space") == 0) keyCode = GLFW_KEY_SPACE;
    else if (strcmp(key, "up") == 0) keyCode = GLFW_KEY_UP;
    else if (strcmp(key, "down") == 0) keyCode = GLFW_KEY_DOWN;
    else if (strcmp(key, "left") == 0) keyCode = GLFW_KEY_LEFT;
    else if (strcmp(key, "right") == 0) keyCode = GLFW_KEY_RIGHT;
    else if (strcmp(key, "a") == 0) keyCode = GLFW_KEY_A;
    else if (strcmp(key, "d") == 0) keyCode = GLFW_KEY_D;
    else if (strcmp(key, "w") == 0) keyCode = GLFW_KEY_W;
    else if (strcmp(key, "s") == 0) keyCode = GLFW_KEY_S;
    else if (strcmp(key, "escape") == 0) keyCode = GLFW_KEY_ESCAPE;
    
    int state = glfwGetKey(g_engine.window, keyCode);
    lua_pushboolean(L, state == GLFW_PRESS);
    
    return 1;
}

static int lua_mouseX(lua_State* L) {
    double x, y;
    glfwGetCursorPos(g_engine.window, &x, &y);
    lua_pushnumber(L, x);
    return 1;
}

static int lua_mouseY(lua_State* L) {
    double x, y;
    glfwGetCursorPos(g_engine.window, &x, &y);
    lua_pushnumber(L, y);
    return 1;
}

static int lua_getClearColor(lua_State* L) {
    lua_newtable(L);
    lua_pushnumber(L, 0.1);
    lua_setfield(L, -2, "r");
    lua_pushnumber(L, 0.1);
    lua_setfield(L, -2, "g");
    lua_pushnumber(L, 0.1);
    lua_setfield(L, -2, "b");
    return 1;
}

static int lua_setClearColor(lua_State* L) {
    float r = luaL_checknumber(L, 1);
    float g = luaL_checknumber(L, 2);
    float b = luaL_checknumber(L, 3);
    glClearColor(r, g, b, 1.0f);
    return 0;
}

static int lua_getWindowSize(lua_State* L) {
    lua_newtable(L);
    lua_pushnumber(L, g_engine.windowWidth);
    lua_setfield(L, -2, "width");
    lua_pushnumber(L, g_engine.windowHeight);
    lua_setfield(L, -2, "height");
    return 1;
}

/* ============================================================ */
/* LUA REGISTRATION */
/* ============================================================ */

void registerLuaFunctions(lua_State* L) {
    lua_newtable(L);
    lua_pushcfunction(L, lua_drawRect);
    lua_setfield(L, -2, "rect");
    lua_pushcfunction(L, lua_drawCircle);
    lua_setfield(L, -2, "circle");
    lua_pushcfunction(L, lua_drawLine);
    lua_setfield(L, -2, "line");
    lua_pushcfunction(L, lua_drawText);
    lua_setfield(L, -2, "text");
    lua_setglobal(L, "draw");
    
    lua_newtable(L);
    lua_pushcfunction(L, lua_keyDown);
    lua_setfield(L, -2, "isDown");
    lua_setglobal(L, "keyboard");
    
    lua_newtable(L);
    lua_pushcfunction(L, lua_mouseX);
    lua_setfield(L, -2, "x");
    lua_pushcfunction(L, lua_mouseY);
    lua_setfield(L, -2, "y");
    lua_setglobal(L, "mouse");
    
    lua_newtable(L);
    lua_pushcfunction(L, lua_getClearColor);
    lua_setfield(L, -2, "getClearColor");
    lua_pushcfunction(L, lua_setClearColor);
    lua_setfield(L, -2, "setClearColor");
    lua_pushcfunction(L, lua_getWindowSize);
    lua_setfield(L, -2, "getWindowSize");
    lua_setglobal(L, "graphics");
}

/* ============================================================ */
/* MAIN LOOP */
/* ============================================================ */

#ifdef __EMSCRIPTEN__
void mainLoopCallback() {
#else
void mainLoop() {
#endif
    double currentTime = glfwGetTime();
    float dt = (float)(currentTime - g_engine.lastTime);
    g_engine.lastTime = currentTime;
    
    /* Call Lua loop(dt) */
    lua_getglobal(g_engine.L, "loop");
    lua_pushnumber(g_engine.L, dt);
    if (lua_pcall(g_engine.L, 1, 0, 0) != LUA_OK) {
        fprintf(stderr, "Lua error in loop: %s\n", lua_tostring(g_engine.L, -1));
        lua_pop(g_engine.L, 1);
    }
    
    /* Clear screen */
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    /* Call Lua window() */
    lua_getglobal(g_engine.L, "window");
    if (lua_pcall(g_engine.L, 0, 0, 0) != LUA_OK) {
        fprintf(stderr, "Lua error in window: %s\n", lua_tostring(g_engine.L, -1));
        lua_pop(g_engine.L, 1);
    }
    
    glfwSwapBuffers(g_engine.window);
    glfwPollEvents();
    
    if (glfwWindowShouldClose(g_engine.window)) {
        g_engine.running = 0;
    }
}

/* ============================================================ */
/* INITIALIZATION */
/* ============================================================ */

int initGLFW(int width, int height) {
    if (!glfwInit()) {
        fprintf(stderr, "Failed to initialize GLFW\n");
        return 0;
    }
    
#ifdef __EMSCRIPTEN__
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
#else
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif
    
    g_engine.window = glfwCreateWindow(width, height, "Game Framework", NULL, NULL);
    if (!g_engine.window) {
        fprintf(stderr, "Failed to create GLFW window\n");
        glfwTerminate();
        return 0;
    }
    
    glfwMakeContextCurrent(g_engine.window);
    glfwSwapInterval(1);
    
    glViewport(0, 0, width, height);
    glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    
    g_engine.windowWidth = width;
    g_engine.windowHeight = height;
    
    return 1;
}

int initLua() {
    g_engine.L = luaL_newstate();
    if (!g_engine.L) {
        fprintf(stderr, "Failed to create Lua state\n");
        return 0;
    }
    
    luaL_openlibs(g_engine.L);
    registerLuaFunctions(g_engine.L);
    
    const char* luaCode =
#include "game.lua.h"
    ;
    
    if (luaL_dostring(g_engine.L, luaCode) != LUA_OK) {
        fprintf(stderr, "Lua error: %s\n", lua_tostring(g_engine.L, -1));
        lua_pop(g_engine.L, 1);
        return 0;
    }
    
    /* Call init() */
    lua_getglobal(g_engine.L, "init");
    if (lua_pcall(g_engine.L, 0, 0, 0) != LUA_OK) {
        fprintf(stderr, "Lua error in init: %s\n", lua_tostring(g_engine.L, -1));
        lua_pop(g_engine.L, 1);
        return 0;
    }
    
    return 1;
}

int initGraphics() {
    g_engine.shaderProgram = createShaderProgram();
    glUseProgram(g_engine.shaderProgram);
    return 1;
}

/* ============================================================ */
/* MAIN */
/* ============================================================ */

#ifdef __EMSCRIPTEN__
int main() {
    if (!initGLFW(1280, 720)) return 1;
    if (!initGraphics()) return 1;
    if (!initLua()) return 1;
    
    g_engine.running = 1;
    g_engine.lastTime = glfwGetTime();
    
    emscripten_set_main_loop(mainLoopCallback, 0, 1);
    
    lua_close(g_engine.L);
    glfwTerminate();
    
    return 0;
}
#else
int main() {
    if (!initGLFW(1280, 720)) return 1;
    if (!initGraphics()) return 1;
    if (!initLua()) return 1;
    
    g_engine.running = 1;
    g_engine.lastTime = glfwGetTime();
    
    while (g_engine.running && !glfwWindowShouldClose(g_engine.window)) {
        mainLoop();
    }
    
    lua_close(g_engine.L);
    glfwTerminate();
    
    return 0;
}
#endif