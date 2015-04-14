all: benchmark
benchmark: benchmark.o serial.o
	gcc -o benchmark benchmark.o serial.o -lm -lpthread
benchmark.o: benchmark.c
	gcc -c benchmark.c
serial.o: serial.c
	gcc -c serial.c
clean:
	rm -rf benchmark send test *.o *~

