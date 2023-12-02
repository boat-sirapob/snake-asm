#include <SDL2/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

const int GRID_WIDTH = 30;
const int GRID_HEIGHT = 20;

const int WINDOW_WIDTH = 640; // window width
const int WINDOW_HEIGHT = WINDOW_WIDTH * GRID_HEIGHT / GRID_WIDTH;

const int CELL_SIZE = (WINDOW_WIDTH/GRID_WIDTH);

const int FRAMES_PER_TICK = 6; // 10 fps
const int FRAMES_PER_SECOND = 60;

extern int snake_x;
extern int snake_y;
extern int snake_x_vel;
extern int snake_y_vel;
extern int snake_tail_x[];
extern int snake_tail_y[];
extern int tail_front;
extern int tail_length;

extern int food_x;
extern int food_y;

extern int score;

extern void initialize_game();
extern void snake_update();

SDL_Window* window;
SDL_Renderer* renderer; 

// for input queue
#define input_queue_length 3
struct InputVelocity {
    int x_vel;
    int y_vel;
};

struct InputVelocity input_queue[input_queue_length];
int input_queue_front = -1;

int initialize_rand() {
    srand(time(NULL));
}

int rand_range(int range_min, int range_max) {
    int result = (rand() % (range_max - range_min)) + range_min;
    // printf("%d\n", result);
    return result;
}

int initialize_window() {
    
    // initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("Failed to initialize the SDL2 library\n");
        return -1;
    }

    // initialize window and renderer
    SDL_CreateWindowAndRenderer(
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        SDL_WINDOW_RESIZABLE,
        &window,
        &renderer
    );

    // set size of game area
    SDL_RenderSetLogicalSize(
        renderer,
        CELL_SIZE*GRID_WIDTH,
        CELL_SIZE*GRID_HEIGHT
    );

    SDL_SetWindowTitle(window, "Snake Game");

    return 0;
}

void draw_cell(int x, int y) {
    // make the cell rect and draw it
    SDL_Rect rect = {x*CELL_SIZE, y*CELL_SIZE, CELL_SIZE, CELL_SIZE};
    SDL_RenderFillRect(renderer, &rect);
}

void draw_snake() {

    // set color to green
    SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);

    // draw each cell of the snake
    int cur_index = tail_front/4;
    for (int i = 0; i < tail_length; i++) {
        // printf("%d %d\n", snake_tail_x[cur_index], snake_tail_y[cur_index]);
        draw_cell(snake_tail_x[cur_index], snake_tail_y[cur_index]);
        cur_index = (cur_index + 1) % (GRID_WIDTH*GRID_HEIGHT);
    }

    // reset color
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);

}

void draw_food() {
    // set color to red
    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);

    draw_cell(food_x, food_y);

    // reset color
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
}

void draw() {

    SDL_RenderClear(renderer);

    draw_snake();
    draw_food();
    
    SDL_RenderPresent(renderer);
}

void print_input_queue() {
    // for debugging

    printf("[");
    if (input_queue_front != -1) {
        printf("(%d, %d)", input_queue[0].x_vel, input_queue[0].y_vel);
    }
    for (int i = 1; i < input_queue_front; i++) {
        printf(", (%d, %d)", input_queue[i].x_vel, input_queue[i].y_vel);
    }
    printf("]\n");
}

int compare_inputs(const struct InputVelocity* a, const struct InputVelocity* b) {
    return (a->x_vel == b->x_vel && a->y_vel == b->y_vel);
}

void process_input() {
    if (input_queue_front == -1) { return; }

    struct InputVelocity new_vel = input_queue[input_queue_front];
    input_queue_front--;

    if (new_vel.x_vel != snake_x_vel && new_vel.y_vel != snake_y_vel) {
        snake_x_vel = new_vel.x_vel;
        snake_y_vel = new_vel.y_vel;
    }
}

void handle_keypress(SDL_Event* event) {

    // to check if new event results in the same velocity
    struct InputVelocity new_vel;
    switch (event->key.keysym.sym) {
    case SDLK_w: case SDLK_UP:
        new_vel.x_vel = 0;
        new_vel.y_vel = -1;
        break;
    case SDLK_a: case SDLK_LEFT:
        new_vel.x_vel = -1;
        new_vel.y_vel = 0;
        break;
    case SDLK_s: case SDLK_DOWN:
        new_vel.x_vel = 0;
        new_vel.y_vel = 1;
        break;
    case SDLK_d: case SDLK_RIGHT:
        new_vel.x_vel = 1;
        new_vel.y_vel = 0;
        break;
    default:
        return;
    }

    // prevent reduntant inputs
    if (input_queue_front != -1 && compare_inputs(&input_queue[input_queue_front], &new_vel)) {
        return;
    }

    // prevent redundant inputs
    if (snake_x_vel == new_vel.x_vel && snake_y_vel == new_vel.y_vel) { return; }

    if ( input_queue_front != input_queue_length-1) {
        input_queue_front++;
    }
    // shift elements up
    for (int i = input_queue_front-1; i >= 0; i--) {
        input_queue[i+1] = input_queue[i];
    }

    // add to queue
    input_queue[0] = new_vel;
}

int main(void) {

    // initialization
    initialize_window();
    initialize_game();
    
    // for handling time
    uint32_t last = 0;
    uint32_t delta = 0;

    int frame = 0;

    // main loop
    SDL_Event event;
    int running = 1;
    while (running) {
        // handle events
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
            case SDL_QUIT:
                running = 0;
                break;
            case SDL_KEYDOWN:
                handle_keypress(&event);
                break;
            }
        }

        // handle time
        uint32_t tick_time = SDL_GetTicks();
        delta = tick_time - last;

        // maintain frames per second
        if (delta < 1000.0/FRAMES_PER_SECOND) {
            continue;
        }
        last = tick_time;
        frame++;

        // maintain game speed
        if (frame < FRAMES_PER_TICK) {
            continue;
        } else {
            frame = 0;
        }

        // game updates
        process_input();
        snake_update();
        draw();
    }

    // destructor
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}

