import std.stdio;
import std.datetime.stopwatch;
static import std.compiler;
import std.bigint;
import std.outbuffer;
import std.string;
import std.container.slist;
import std.range : popFront, walkLength;
import std.math;


struct BenchTime {
  string name;
  double real_time;
  double user_time;
  int sys = 0;
  int consed = 0;
}

auto bench_time(void function() fctn, int times, string name) {
  auto sw = StopWatch(AutoStart.no);

  sw.start();
  foreach(i; 0 .. times) {
    fctn();
  }
  sw.stop();

  long msecs = sw.peek.total!"msecs";
          
  BenchTime bt = { name:name, real_time: msecs / 1000.0, user_time: msecs / 1000.0 };
  return bt;
}

void run(string name, int times, void function() fctn) {
  BenchTime bt = bench_time(fctn, times, name);
  writefln(";;; running #<benchmark %s for %s runs>", name, times);
  writefln("(\"%s\" %s %s %d %d)", bt.name, bt.real_time, bt.user_time, bt.sys, bt.consed);
}

const int fib_iter = 25;

int fib (int n)
{
  if (n < 2) {
    return 1;
  } else {
    return fib(n - 1) + fib(n - 2);
  }
}

void run_fib() {
  fib(fib_iter);
}

float fib_single_float(float n) {
  if (n < 2) {
    return 1;
  } else {
    return fib_single_float(n-1) + fib_single_float(n-2);
  }
}

void run_fib_single_float() {
  fib_single_float(cast(float) fib_iter);
}


float fib_double_float(float n) {
  if (n < 2) {
    return 1;
  } else {
    return fib_double_float(n-1) + fib_double_float(n-2);
  }
}

void run_fib_double_float() {
  fib_double_float(cast(float) fib_iter);
}

int ackermann(int m, int n) {
  if (m == 0) {
    return n + 1;
  } else if (n == 0) {
    return ackermann(m-1, 1);
  } else {
    return ackermann(m-1, ackermann(m, n-1));
  }
}

void run_ackermann() {
  ackermann(3, 11);
}


int tak(int x, int y, int z) {
  if (!(y < x)) {
    return z;
  } else {
    return tak(tak(x-1, y, z),
               tak(y-1, z, x),
               tak(z-1, x, y));
  }
}

void run_tak() {
  tak(18, 12, 6);
}

BigInt factorial(BigInt n) {
  if (n == BigInt("0")) {
    return BigInt("1");
  } else {
    return n * factorial(n - BigInt("1"));
  }
}

void run_factorial() {
  factorial(BigInt("500"));
}

void bench_string_concat(int size, int runs) {
  foreach(cnt; 0 .. runs) {
    long buflen;
    OutBuffer buf = new OutBuffer();
    foreach(i; 0 .. size) {
      buf.write("hi there!");
    }
    buflen = buf.toString().length;
    assert(buflen == size*("hi there!".length));
  }
}

void bench_1d_arrays(int size, int runs) {
  int[] ones, twos, threes;
  ones.length = twos.length = threes.length = size;

  ones[] = 1;
  twos[] = 2;

  foreach(run; 0 .. runs) {
    foreach(pos; 0 .. threes.length) {
      threes[pos] = ones[pos] + twos[pos];
    }
    foreach(elt; threes) {
      assert(elt == 3, format("The assertion %s == 3 failed.", elt));
    }
  }
}

void run_bench_1d_arrays() {
  bench_1d_arrays(100000, 10);
}

void bench_2d_arrays(int size, int runs) {
  uint[][] ones = new uint[][](size, size);
  uint[][] twos = new uint[][](size, size);
  uint[][] threes = new uint[][](size, size);

  foreach(i; 0 .. size) {
    foreach(j; 0 .. size) {
      ones[i][j] = 1;
      twos[i][j] = 2;
    }
  }
  
  foreach(run; 0 .. runs) {
    foreach(i; 0 .. size) {
      foreach(j; 0 .. size) {
        threes[i][j] = ones[i][j] + twos[i][j];
      }
    }
    int elt = threes[3][3];
    assert(elt == 3, format("The assertion %s == 3 failed.", elt));
  }
}

void run_bench_2d_arrays() {
  bench_2d_arrays(2000, 10);
}


int[] listn(int n) {
  if (!(n == 0)) {
    return listn(n-1) ~ n;
  } else {
    return new int[](0);
  }
}

bool shorterp(int[] x, int[] y) {
  return y.length > 0 && (x.length == 0 || shorterp(x[1 .. x.length], y[1 .. y.length]));
}

int[] mas(int[] x, int[] y, int[] z) {
  if (!(shorterp(y, x))) {
    return z;
  } else {
    return mas(mas(x[1 .. x.length], y, z),
               mas(y[1 .. y.length], z, x),
               mas(z[1 .. z.length], x, y));
  }
}

void run_takl() {
  mas(listn(18), listn(12), listn(6));
}

auto sl_listn(int n) {
  auto ans = SList!int();
  foreach(i; 0 .. n) {
    ans.insertFront(0);
  }
  return ans;
}

bool sl_shorterp(SList!int x, SList!int y) {
  auto x_next = x.dup;
  auto y_next = y.dup;
  !x_next.empty && x_next.removeFront;
  !y_next.empty && y_next.removeFront;
  return !y.empty && (x.empty || sl_shorterp(x_next, y_next));
}

auto sl_mas(SList!int x, SList!int y, SList!int z) {
  if (!(sl_shorterp(y, x))) {
    return z;
  } else {
    auto x_next = x.dup;
    auto y_next = y.dup;
    auto z_next = z.dup;
    !x_next.empty && x_next.removeFront;
    !y_next.empty && y_next.removeFront;
    !z_next.empty && z_next.removeFront;
    return sl_mas(sl_mas(x_next, y, z),
                  sl_mas(y_next, z, x),
                  sl_mas(z_next, x, y));
  }
}

void sl_run_takl() {
  writeln(sl_mas(sl_listn(18), sl_listn(12), sl_listn(6))[]);
}

long crc_division_step(ubyte bit, long rmdr, long poly, long msb_mask) {
  // Shift in the bit into the LSB of the register (rmdr)
  long new_rmdr = bit | (rmdr * 2);
  // Divide by the polynomial, and return the new remainder
  if (0 == (msb_mask & new_rmdr)) {
    return new_rmdr;
  } else {
    return new_rmdr ^ poly;
  }
}

long integer_length(long n) {
  if (n < 0) {
    n = -n;
  } else {
    n++;
  }
  auto ans = log2(n);
  return cast(long) ceil(ans);
}

long compute_adjustment(long poly, long n) {
  // Precompute X^(n-1) mod poly
  long poly_len_mask = cast(long)1 << (integer_length(poly) - 1);
  long rmdr = crc_division_step(1, 0, poly, poly_len_mask);
  foreach(k; 0 .. n-1) {
    rmdr = crc_division_step(0, rmdr, poly, poly_len_mask);
  }
  return rmdr;
}

long calculate_crc40(uint iterations) {
  long crc_poly = 1099587256329;
  long len = 3014633;
  long answer = 0;
  foreach(k; 0 .. iterations) {
    answer = compute_adjustment(crc_poly, len);
  }
  return answer;
}

void run_crc40() {
  calculate_crc40(10);
}

void main()
{
  writefln("(\"%s %d.%04d\"", std.compiler.name, std.compiler.version_major, std.compiler.version_minor);
  run("CRC40", 2, &run_crc40);
  run("1D-ARRAYS", 1, &run_bench_1d_arrays);
  run("2D-ARRAYS", 1, &run_bench_2d_arrays);
  run("FIB", 50, &run_fib);
  //run("FIB-RATIO", 500, run_fib_ratio);
  run("FIB-SINGLE-FLOAT", 50, &run_fib_single_float);
  run("FIB-DOUBLE-FLOAT", 50, &run_fib_double_float);
  run("ACKERMANN", 1, &run_ackermann);
  run("TAK", 1000, &run_tak);
  run("TAKL", 150, &run_takl);
  //run("SL-TAKL", 1, &sl_run_takl);
  run("FACTORIAL", 1000, &run_factorial);
  run("STRING-CONCAT", 1, function () { bench_string_concat(1000000, 100); });
  writefln(")");
}
