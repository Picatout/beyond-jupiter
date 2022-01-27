// tool to get powers of 10 needed by the parser in strtof.s in hexadecimal format
// then accept any float. 
// CTRL+C exit program.

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

const float powersOf10[6] = {	// Table giving binary powers of 10.  Entry 
					10.0f,			// is 10^2^i.  Used to convert decimal 
					100.0f,			// exponents into floating-point numbers. 
					1.0e4f,
					1.0e8f,
					1.0e16f,
					1.0e32f
};

void main(){
	int i;
	float f;
	int32_t *pi32;
    for (i=0;i<6;i++){
	  pi32=(int32_t*)&powersOf10[i];
	  printf("%e -> 0x%X\n",powersOf10[i],*pi32);
	}
	puts("try any float, CTRL+C to exit");
    while (1){
	   printf("float? ");
	   scanf("%f",&f);
	   pi32=(int32_t*)&f;
	   printf("0x%X\n",*pi32);
	}
}

