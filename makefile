main: main.c snake.s utils.s
	gcc -g -o main.o -c main.c
	as -g snake.s -o snake.o
	as -g utils.s -o utils.o
	gcc -g -o main main.o snake.o utils.o -lSDL2
	make clean
clean:
	rm *.o
clear:
	make clean
	rm main