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

/* Reads back what has been drawn to the current frame and writes it as a
 * BMP. Call it after drawing and before Present: the contents of the back
 * buffer after a present are not defined. 1 on success, 0 on failure.
 */
int SaveBMP(void *renderer, const char *path) {
  SDL_Renderer *r = (SDL_Renderer *)renderer;
  int w, h, ok;
  SDL_Surface *s;
  if (SDL_GetRendererOutputSize(r, &w, &h) != 0) return 0;
  s = SDL_CreateRGBSurfaceWithFormat(0, w, h, 32, SDL_PIXELFORMAT_ARGB8888);
  if (!s) return 0;
  ok = SDL_RenderReadPixels(r, NULL, SDL_PIXELFORMAT_ARGB8888, s->pixels, s->pitch) == 0
       && SDL_SaveBMP(s, path) == 0;
  SDL_FreeSurface(s);
  return ok ? 1 : 0;
}

void DrawLine(void *renderer, int x0, int y0, int x1, int y1) {
  SDL_RenderDrawLine((SDL_Renderer *)renderer, x0, y0, x1, y1);
}

/* Fills a convex quadrilateral (the iso tiles, and later the flat-shaded
 * faces units are drawn as) by horizontal scanline -- one SDL_RenderDrawLine
 * per row rather than per pixel. SDL2 has no polygon fill of its own without
 * SDL_RenderGeometry, whose vertex arrays are exactly the kind of struct
 * catmint's FFI cannot pass, so this stays scalar-in like everything else
 * here. Edge intersections use a half-open [y0, y1) test per edge so a
 * scanline through a shared vertex is not counted twice.
 */
void FillQuad(void *renderer, int x0, int y0, int x1, int y1,
                               int x2, int y2, int x3, int y3) {
  SDL_Renderer *r = (SDL_Renderer *)renderer;
  int xs[4] = {x0, x1, x2, x3};
  int ys[4] = {y0, y1, y2, y3};
  int minY = ys[0], maxY = ys[0], i, y;
  for (i = 1; i < 4; i++) {
    if (ys[i] < minY) minY = ys[i];
    if (ys[i] > maxY) maxY = ys[i];
  }
  for (y = minY; y <= maxY; y++) {
    int lo = 0, hi = 0, have = 0;
    for (i = 0; i < 4; i++) {
      int ax = xs[i], ay = ys[i];
      int bx = xs[(i + 1) % 4], by = ys[(i + 1) % 4];
      if (ay == by) continue;
      if ((y >= ay && y < by) || (y >= by && y < ay)) {
        int x = ax + (bx - ax) * (y - ay) / (by - ay);
        if (!have) { lo = hi = x; have = 1; }
        else { if (x < lo) lo = x; if (x > hi) hi = x; }
      }
    }
    if (have) SDL_RenderDrawLine(r, lo, y, hi, y);
  }
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
