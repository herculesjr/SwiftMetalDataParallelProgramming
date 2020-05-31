
#include <metal_stdlib>
using namespace metal;
/// This is a Metal Shading Language (MSL) function equivalent to the add_arrays() C function, used to perform the calculation on a GPU.
kernel void add_array_item(device const float* inA,
                       device const float* inB,
                       device float* result,
                       uint index [[thread_position_in_grid]])
{
    // the for-loop is replaced with a collection of threads, each of which
    // calls this function.
    result[index] = inA[index] + inB[index];
}

kernel void compare_array_item(device const float* inA,
                       device const float* inB,
                       device bool* result,
                       uint index [[thread_position_in_grid]])
{
    // the for-loop is replaced with a collection of threads, each of which
    // calls this function.
    result[index] = inA[index] == inB[index];
}

kernel void all_true_array(device const bool* in,
                       device bool* result,
                       uint index [[thread_position_in_grid]])
{
    bool compareResult = true;
    for (uint i = 0; i <= index; i++) {
        compareResult = compareResult && in[i];
    }
    *result = compareResult;
}
