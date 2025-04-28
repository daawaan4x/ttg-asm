#include <stdio.h>
#include <conio.h>

#include ".\table.c"

int main() {
	
	char* variables[] = {"P", "Q"};
	int values[] = {
		1, 1, 
		1, 0, 
		0, 1,
		0, 0,
	};

	print_table(
		4,
		2,
		variables,
		values
	);

	getch();
	return 0;
}