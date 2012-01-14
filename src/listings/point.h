typedef struct _Point {
  int x, y;
} Point;

void move(Point *pt, int dx, int dy);

Point* copy_with_offset(Point *pt, int dx, int dy);
