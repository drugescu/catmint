/* sdl_shim.c -- flat, scalar-only bridge from catmint's FFI to SDL2.
 *
 * catmint's extern/unsafe boundary marshals only integers, Float, Ptr,
 * String (in, as a const char *) and Bytes/Ints/Floats (as a data pointer)
 * -- never an arbitrary C struct. SDL2's window and renderer calls are
 * already scalar; only event polling needs one (SDL_Event), so the last
 * polled event is kept here in static storage and read back through
 * scalar getters instead of handing a struct pointer across the boundary.
 *
 * Every function below is called by its bare name from an `extern class` in
 * rps.cm: catmint suppresses mangling for extern declarations, so the
 * linked symbol is exactly the name written there. Names are kept short on
 * purpose -- the catmint side already namespaces each call as `SDL.Foo()`.
 */
#define SDL_MAIN_HANDLED
#include <SDL2/SDL.h>

static SDL_Event g_event;

int Init(void) {
  return SDL_Init(SDL_INIT_VIDEO) == 0 ? 1 : 0;
}

void *CreateWindow(const char *title, int w, int h) {
  return SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                           w, h, SDL_WINDOW_SHOWN);
}

void *CreateRenderer(void *window) {
  return SDL_CreateRenderer((SDL_Window *)window, -1,
                             SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
}

void SetColor(void *renderer, int r, int g, int b, int a) {
  SDL_SetRenderDrawColor((SDL_Renderer *)renderer, r, g, b, a);
}

void Clear(void *renderer) {
  SDL_RenderClear((SDL_Renderer *)renderer);
}

void Present(void *renderer) {
  SDL_RenderPresent((SDL_Renderer *)renderer);
}

/* Pops one event off the queue into static storage; 1 if there was one. */
int PollEvent(void) {
  return SDL_PollEvent(&g_event) ? 1 : 0;
}

int EventIsQuit(void) {
  return g_event.type == SDL_QUIT ? 1 : 0;
}

int EventIsKeyDown(void) {
  return g_event.type == SDL_KEYDOWN ? 1 : 0;
}

int EventKey(void) {
  return (int)g_event.key.keysym.sym;
}

void Delay(int ms) {
  SDL_Delay((Uint32)ms);
}

void DestroyRenderer(void *renderer) {
  SDL_DestroyRenderer((SDL_Renderer *)renderer);
}

void DestroyWindow(void *window) {
  SDL_DestroyWindow((SDL_Window *)window);
}

void Quit(void) {
  SDL_Quit();
}
