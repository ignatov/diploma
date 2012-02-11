typedef struct _Point {
  int x, y;
} Point;

void move(Point *pt, int dx, int dy);

Point* clone(Point *pt);
