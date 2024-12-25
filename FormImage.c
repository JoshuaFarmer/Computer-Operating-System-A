/* FORM A DISK IMAGE FROM GIVEN FILES */

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#pragma pack(1)

typedef struct 
{
	char  Sign[7];
	short Entry;
	short Version;
	short Sectors;
	char  Reserved2[5];
	char  Magic;
	short Origin; // Ignored
	char  NameLen;
	char  NameAndFirst[512-(17)];
} Header;

Header construct_header(const char* name, size_t size)
{
	Header h;
	h.NameLen = strlen(name);
	h.Magic = 0xAA;
	h.Sectors = size/512;
	h.Version = 2;
	memcpy(h.Sign, "COSA E", 7);
	memcpy(h.NameAndFirst, name, h.NameLen);
	FILE* fp = fopen(name, "rb");
	fread(h.NameAndFirst+h.NameLen, 1, 512, fp);
	fclose(fp);
	return h;
}

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

		printf("FILE: "); 
		for (int u = 0; u < buff.NameLen; ++u)
			printf("%c",buff.NameAndFirst[u]);
		printf("; WITH SIZE %d\n", buff.Sectors*512);

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
