#include <iostream>
#include <SDL2/SDL.h>
#include <cmath>
#include <cstdlib>
#include <ctime>

const int SCREEN_WIDTH = 900;
const int SCREEN_HEIGHT = 900;
const float dt = 0.31f;
const float G = 6.67408e-11;
const float CENTRAL_MASS = 26.44e12;

struct Star {
    float x, y;
    float mass;
    float vx, vy;
    float brightness, opacity; 
};

struct DarkMatter {
    float x, y;
    float mass;
    float vx, vy;
};

__device__ float calculateEscapeVelocity(Star* star, float distance) {
    return sqrtf(2 * G * star->mass / distance);
}

__global__ void updateStars(Star* stars, int numStars, float dt) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    const float MAX_FORCE = 1e-5f;
    const float MIN_BRIGHTNESS = 0.1f;
    if (i < numStars) {
        for (int j = 0; j < numStars; j++) {
            if (i != j) {
                float dx = stars[j].x - stars[i].x;
                float dy = stars[j].y - stars[i].y;
                float dist = sqrtf(dx * dx + dy * dy) + 1e-5f;
                float escapeVelocity = calculateEscapeVelocity(&stars[j], dist);
                float distanceSquared = dx * dx + dy * dy + 1e-5f;
                float force = G * stars[j].mass * stars[i].mass / (distanceSquared);
                stars[i].brightness += MAX_FORCE / ((SCREEN_WIDTH / 2) * (SCREEN_HEIGHT / 2) );
                stars[i].brightness = min(max(stars[i].brightness, MIN_BRIGHTNESS), 1.0f);
                float ax = force * (dx / sqrt(distanceSquared)) / stars[i].mass;
                float ay = force * (dy / sqrt(distanceSquared)) / stars[i].mass;
                stars[i].vx += ax * dt;
                stars[i].vy += ay * dt;
            }
        }
        stars[i].x += stars[i].vx * dt / 2;
        stars[i].y += stars[i].vy * dt / 2;
    }
}

int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* window = SDL_CreateWindow("Galaxy Simulation", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    const float tiltAngle = M_PI / 8; // 30 degrees, for example
    const int numStars = 25500;
    Star* stars;
    cudaMallocManaged(&stars, numStars * sizeof(Star));

    srand(static_cast<unsigned int>(time(NULL)));
    stars[0].x = SCREEN_WIDTH / 2;
    stars[0].y = SCREEN_HEIGHT / 2;
    stars[0].vx = 0;
    stars[0].vy = 0;
    stars[0].mass = CENTRAL_MASS;

    int offsetX = 0, offsetY = 0;
    for (int i = 1; i < numStars; i++) {
        float radius = static_cast<float>(rand()) / RAND_MAX * (SCREEN_WIDTH / 2) / 2;
        float angle = static_cast<float>(rand()) / RAND_MAX * 2.0f * M_PI;
        stars[i].opacity = static_cast<float>(rand()) / RAND_MAX;
        stars[i].x = SCREEN_WIDTH / 2 + radius * cosf(angle) - offsetX;
        stars[i].y = SCREEN_HEIGHT / 2 + radius * sinf(angle) - offsetY;

        float velocity = sqrt(G * CENTRAL_MASS / radius);
        stars[i].vx = -velocity * sinf(angle); 
        stars[i].vy = velocity * cosf(angle);
        stars[i].mass = 1 + static_cast<float>(rand()) / (static_cast<float>(RAND_MAX / (1e7 - 1e6)));
    }

    const int numThreads = 512;
    const int numBlocks = (numStars + numThreads - 1) / numThreads;
    float zoom = 1.0f; 
    bool quit = false;
    bool isDragging = false;
    int lastMouseX, lastMouseY;
    while (!quit) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
        switch (event.type) {
                        case SDL_QUIT:
                            quit = true;
                            break;
                        case SDL_MOUSEBUTTONDOWN:
                            if (event.button.button == SDL_BUTTON_LEFT) {
                                isDragging = true;
                                lastMouseX = event.button.x;
                                lastMouseY = event.button.y;
                            }
                            break;
                        case SDL_MOUSEBUTTONUP:
                            if (event.button.button == SDL_BUTTON_LEFT) {
                                isDragging = false;
                            }
                            break;
                        case SDL_MOUSEMOTION:
                            if (isDragging) {
                                int mouseX, mouseY;
                                SDL_GetMouseState(&mouseX, &mouseY);

                                offsetX += mouseX - lastMouseX;
                                offsetY += mouseY - lastMouseY;

                                lastMouseX = mouseX;
                                lastMouseY = mouseY;
                            }
                        case SDL_MOUSEWHEEL:
                            case SDL_KEYDOWN:
                                if (event.key.keysym.sym == SDLK_q) {
                                    zoom *= 1.01f; // zoom in
                                }
                                else if (event.key.keysym.sym == SDLK_a) {
                                    zoom /= 1.01f; // zoom out
                                }
                                break;
                        }
                    }

            updateStars<<<numBlocks, numThreads>>>(stars, numStars, dt);
            cudaDeviceSynchronize();

            SDL_SetRenderDrawColor(renderer, 22, 22, 22, 255); 
            SDL_RenderClear(renderer);


        for (int i = 0; i < numStars; i++) 
        {        
            float tiltedY = stars[i].y + tan(tiltAngle) * stars[i].x;
            SDL_SetRenderDrawColor(renderer, 255 / stars[i].brightness, 255, 102, stars[i].opacity * 255); 
            SDL_RenderDrawPoint(renderer, (stars[i].x + (offsetX - 600) + tiltedY) * zoom, (stars[i].y + offsetY) * zoom);
        }
        SDL_RenderPresent(renderer);
    }

    cudaFree(stars);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
 


