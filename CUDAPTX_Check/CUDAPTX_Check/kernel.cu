
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

union  LoadData {
	long long Load;
	short DivData[4];
};

__device__ short DeviceMem[10000];
__global__ void LoadCheck_Rem(int Ret) {
	int x = threadIdx.x;
	unsigned long long LoadReg;
	unsigned long long RefReg = 0x000000000000FFFF;
	long long * lpDev = (long long  *)DeviceMem;
	LoadReg = __ldg(&lpDev[x]);
	int Clock;
	asm volatile (
		"mov.u32 %0, %clock;\n\t"
		:"=r"(Clock)
		);

	__shared__ short Cost[4];
	Cost[0] = (short)((LoadReg & RefReg)	  );
	RefReg <<= 16;
 	Cost[1] = (short)((LoadReg &  RefReg)>>16);
	RefReg <<= 16;
	Cost[2] = (short)((LoadReg & RefReg) >> 32);
	RefReg <<= 16;
	Cost[3] = (short)((LoadReg & RefReg) >> 48);
	int minCost = Cost[0];
	int Ref;
	int RefFwdData = 1;
	for (int nLoop = 1; nLoop < 1000; nLoop++) {
		int Ref = nLoop % 4;
		if (Ref == 1) {
			LoadReg = lpDev[x + RefFwdData++];
		}
		if (Cost[0] < minCost) {
			minCost = Cost[0];
		}
		if (x + 1 + nLoop >= 10000) {
			break;
		}
		Cost[0] = Cost[1];
		Cost[1] = Cost[2];
		Cost[2] = Cost[3];
		Cost[3] = 0;
		if (Ref == 0) {
			// Get short on Reg 
			Cost[0] = (short)((LoadReg & 0x000000000000FFFF)		);
			Cost[1] = (short)((LoadReg & 0x00000000FFFF0000) >> 16	);
			Cost[2] = (short)((LoadReg & 0x0000FFFF00000000) >> 32	);
			Cost[3] = (short)((LoadReg & 0xFFFF000000000000) >> 48	);
		}
	}
}
__global__ void LoadCheck(int Ret) {
	int x = threadIdx.x;
	short Cost = DeviceMem[x];
	int minCost = Cost;
	int Ref;
	int RefFwdData = 1;
	if (x + 1  < 10000) {
		for (int nLoop = 1; nLoop < 1000; nLoop++) {
			Cost = DeviceMem[x+nLoop];
			if (Cost < minCost) {
				minCost = Cost;
			}
		}
	}
}
int main()
{
	int x, y, z;
	x = 0;
	y = 0;
	z = 0;
	LoadCheck << <1, 1024 >> > (x);
	LoadCheck_Rem << <1, 1024 >> > (x);

    return 0;
}
