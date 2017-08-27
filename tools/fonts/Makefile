mkfont:
	gcc mkfont.c -o mkfont
	echo char hankaku[4096]={ > font.c
	./mkfont >> font.c
	echo }\; >>font.c
