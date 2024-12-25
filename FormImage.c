/* FORM A DISK IMAGE FROM GIVEN FILES */

#include<stdio.h>
#include<stdlib.h>
#pragma pack(1)

typedef struct 
{
	char  Reserved[8];
	char  Sign[7];
	short Entry;
	short Version;
	short Sectors;
	char  Reserved2[5];
	char  Magic;
	short Origin; // Ignored
	char  Name[8];
	char  First[512-37];
} Header;

int main(int argc, char **argv)
{
	if (argc < 4)
		exit(1);
	FILE* Image = fopen(argv[1], "wb");
	FILE* Loader = fopen(argv[2], "rb");
	size_t LoaderSize = strtoul(argv[3], NULL, 0);
	char LoaderCode[LoaderSize];
	fread((void*)LoaderCode, LoaderSize, 1, Loader);
	fwrite((void*)LoaderCode, LoaderSize, 1, Image);

	for (int x = 4; x < argc; ++x)
	{
		FILE* File = fopen(argv[x], "rb");
		Header buff;
		fread((void*)&buff, sizeof(Header), 1, File);

		// Header
		fwrite((void*)&buff, sizeof(Header), 1, Image);

		size_t SectorsToRead=buff.Sectors-1;
		for (size_t y = 0; y < SectorsToRead; ++y)
		{
			fread((void*)&buff, sizeof(Header), 1, File);
			fwrite((void*)&buff, sizeof(Header), 1, Image);
		}

		fclose(File);
	}

	// End FS
	char c = 255;
	for (size_t x = 0; x < 512; ++x)
		fwrite((void*)&c, 1, 1, Image);
	fclose(Image);
	fclose(Loader);
	printf("Created Disk Image");
}
