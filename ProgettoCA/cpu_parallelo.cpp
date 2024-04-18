#include <iostream>
#include <pthread.h>
#include <time.h>
#include <math.h>

using namespace std;

const int MAX = 1000;
int a[MAX];
int num_threads = 8;

clock_t somma_ricorsione = 0;

void create_division(int& low, int& high, int thread_part){
    int resto = MAX % num_threads;
    low = thread_part * (MAX / num_threads);
    if (thread_part >= 1 && thread_part <= resto)
        low += thread_part;
    if (thread_part > resto)
        low += resto;

    int c = (thread_part + 1) * (MAX / num_threads);
    if (thread_part < resto)
        c += thread_part;
    else
        c += resto-1;

    high = c < MAX? c : MAX;
}

void merge(int low, int mid, int high)
{
    int* left = new int[mid - low + 1];
    int* right = new int[high - mid];

    int n1 = mid - low + 1, n2 = high - mid, i, j;

    for (i = 0; i < n1; i++)
        left[i] = a[i + low];

    for (i = 0; i < n2; i++)
        right[i] = a[i + mid + 1];

    int k = low;
    i = j = 0;

    while (i < n1 && j < n2) {
        if (left[i] <= right[j])
            a[k++] = left[i++];
        else
            a[k++] = right[j++];
    }

    while (i < n1) {
        a[k++] = left[i++];
    }

    while (j < n2) {
        a[k++] = right[j++];
    }

    delete[] left;
    delete[] right;
}

void merge_sort(int low, int high)
{
    if (low < high) {
        int mid = low + (high - low) / 2;

        clock_t t3, t4;
        t3 = clock();
        merge_sort(low, mid);
        merge_sort(mid + 1, high);
        t4 = clock();
        somma_ricorsione += (t4-t3);

        merge(low, mid, high);
    }
}

void* merge_sort_thread(void* arg)
{
    int thread_part = *(int*) arg;
    int low, high;

    create_division(low, high, thread_part);
    merge_sort(low, high);
}

int main()
{
    int* arguments[num_threads];
    for(int i = 0; i < num_threads; i++){
        arguments[i] = (int*)malloc(sizeof(int));
        *arguments[i] = i;
    }

    for (int i = 0; i < MAX; i++)
        a[i] = MAX - i;


    clock_t t1, t2;

    t1 = clock();

    pthread_t threads[num_threads];

    for (int i = 0; i < num_threads; i++)
        pthread_create(&threads[i], NULL, merge_sort_thread, arguments[i]);

    for (int i = 0; i < num_threads; i++)
        pthread_join(threads[i], NULL);

    int start, e, tmp, mid;

    int k = (num_threads%2 == 1 || (num_threads%2 == 0 && !((num_threads & (num_threads - 1)) == 0)));

    for(int j = 2; j < num_threads; j = j*2){
        for(int i = 0; i < num_threads/j + k; i++){
            
            create_division(start, tmp, i*j);
            create_division(tmp, e, ((i+1)*j)-1);
            create_division(tmp, mid, ((i*j)+(((i+1)*j)-1))/2);

            merge(start, mid, e);
        }
 }

    merge(0, start-1 , MAX);
        
    t2 = clock();

    cout << endl << "Time taken: " << (t2 - t1) / (double)CLOCKS_PER_SEC << " seconds" << endl;
    
    return 0;
}