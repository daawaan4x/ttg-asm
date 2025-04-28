#include <stdio.h>

void print_table(int rows, int cols, char** headers, int* values) {
	int y, x;

	for (x = 0; x < cols; x++) {
		int i = x;
		char* header = headers[i];
		printf(header);
		printf("\t");
	}

	printf("\n");

	for (y = 0; y < rows; y++) {

		for (x = 0; x < cols; x++) {
			int i = y * cols + x;
			int value = values[i];
			if (value) printf("True");
			else printf("False");
			printf("\t");	
		}
		
		printf("\n");
	}

	
}