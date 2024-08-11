#include <fstream>

using namespace std;

int main()
{
    ofstream myFile ("data.bin", ios::binary);
    const int data_sz = 32;

    // sz: 64, 128, 256, 512, 1024, 2048, 4096
    for (int i = 1; i < 8; i++) {
         if (i != 1)
             myFile.open ("data.bin", fstream::out | fstream::app);

         int sz = data_sz * (1 << i);
         char *b = new char[sz];
         myFile.write (b, sz);
         myFile.close();
         delete [] b;

    }

    return 0;
}


