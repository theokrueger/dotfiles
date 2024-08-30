/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nogroup";

static const char *colorname[NUMCOLS] = {
	[BACKGROUND] =   "#3e4637",     /* after initialization */
	[INIT] =   "#91863c",     /* after initialization */
	[INPUT] =  "#c4b550",   /* during input */
	[FAILED] = "#a0aa95",   /* wrong password */
};

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 1;

/* grid size and pos */
static const int logosize = 25;
static const int logow = 0;
static const int logoh = 0;

static XRectangle rectangles[] = {
	/* x	y	w	h */
	/* smiley */
	{ 1,	0,	1,	2 },
	{ 3,	0,	1,	2 },
	{ 0,	3,	1,	1 },
	{ 1,	4,	3,	1 },
	{ 4,	3,	1,	1 },
	/* L */
	{ 7,	0,	1,	5 },
	{ 8,	4,	2,	1 },
	/* O */
	{ 11,	0,	3,	1 },
	{ 11,	4,	3,	1 },
	{ 11,	1,	1,	3 },
	{ 13,	1,	1,	3 },
	/* C */
	{ 15,	0,	1,	5 },
	{ 16,	0,	2,	1 },
	{ 16,	4,	2,	1 },
	/* K */
	{ 19,	0,	1,	5 },
	{ 20,	2,	1,	1 },
	{ 21,	0,	1,	2 },
	{ 21,	3,	1,	2 },
	/* E */
	{ 23,	0,	1,	5 },
	{ 24,	0,	2,	1 },
	{ 24,   2,      2,      1 },
	{ 24,   4,      2,      1 },
	/* D */
	{ 27,	0,	1,	5 },
	{ 28,	0,	1,	1 },
	{ 28,	4,	1,	1 },
	{ 29,	1,	1,	3 },
};
