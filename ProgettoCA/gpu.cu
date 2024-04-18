#include <iostream>
#include <sys/time.h>
#include <math.h>
#include <cuda_profiler_api.h>
#include <cuda_runtime.h>

void readList(long**);
void mergesort(long*);
__global__ void gpu_mergesort(long*, long*, long, long);
__device__ void gpu_bottomUpMerge(long*, long*, long, long, long);

#define min(a, b) (a < b ? a : b)
#define size 1000000
#define NumThreads 1024
#define NumBlocks 65535

int main(int argc, char** argv) {

    cudaEvent_t start, stop;
    float elapsedTime;

    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    long *data;
    readList(&data);

    cudaEventRecord(start);

    mergesort(data);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&elapsedTime, start, stop);

    printf("Tempo di esecuzione: %f secondi\n", float(elapsedTime/1000));

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

}

void mergesort(long* data){
    long* D_data;
    long* D_swp;

    cudaMalloc((void**) &D_data, size * sizeof(long));
    cudaMalloc((void**) &D_swp, size * sizeof(long));

    cudaMemcpy(D_data, data, size * sizeof(long), cudaMemcpyHostToDevice);

    long* A = D_data;
    long* B = D_swp;

    long nThreads = NumThreads * NumBlocks;


    for (int width = 2; width < (size << 1); width <<= 1) {
        long slices = size / ((nThreads) * width) + 1;

        gpu_mergesort<<<NumBlocks, NumThreads>>>(A, B, width, slices);

        A = A == D_data ? D_swp : D_data;
        B = B == D_data ? D_swp : D_data;
    }

    cudaMemcpy(data, A, size * sizeof(long), cudaMemcpyDeviceToHost);

    cudaFree(A);
    cudaFree(B);
}

__global__ void gpu_mergesort(long* source, long* dest, long width, long slices) {
    unsigned int idx = threadIdx.x + blockIdx.x*NumThreads;
    long start = width*idx*slices,
         middle,
         end;

    for (long slice = 0; slice < slices; slice++) {
        if (start >= size)
            break;
             middle = min(start + (width >> 1), size);
        end = min(start + width, size);
        gpu_bottomUpMerge(source, dest, start, middle, end);
        start += width;
    }
}

__device__ void gpu_bottomUpMerge(long* source, long* dest, long start, long middle, long end) {
    long __align__ (8) i = start;
    long __align__ (8) j = middle;
    for (long k = start; k < end; k++) {
        if (i < middle && (j >= end || source[i] < source[j])) {
            dest[k] = source[i];
            i++;
        } else {
            dest[k] = source[j];
            j++;
        }
    }
}

typedef struct {
    int v;
    void* next;
} LinkNode;

void readList(long** list) {
    LinkNode* node = 0;
    LinkNode* first = 0;
    for (long v=size; v>0; v--) {
        LinkNode* next = new LinkNode();
        next->v = v;
        if (node)
            node->next = next;
        else
            first = next;
        node = next;
    }

    *list = new long[size];
    node = first;
    long i = 0;
    while (node) {
       (*list)[i++] = node->v;
       node = (LinkNode*) node->next;
    }
}