// Deliberately independent of OpenCV and the C++ standard library.
#include <stdio.h>

int main()
{
    return puts("native GNAT link probe ok") < 0;
}