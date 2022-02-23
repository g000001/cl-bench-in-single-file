use std::time::SystemTime;

fn bench_time(fctn: fn() -> (), times: i32, name: String) -> (String, f32, f32, i32, i32) {
    let sys_time = SystemTime::now();
    for _ in 0..times {
        fctn();
    }
    let real_time = sys_time.elapsed().unwrap().as_secs_f32();
    (name, real_time, real_time, 0, 0)
}

fn run(name: String, times: i32, fctn: fn() -> ()) -> () {
    let (name, rt, ut, sys, consed) = bench_time(fctn, times, name);
    println!(";;; running #<benchmark {} for {} runs>", name, times);
    println!("(\"{}\" {} {} {} {})", name, rt, ut, sys, consed);
}

const FIB_ITER: i32 = 25;

fn fib(n: i32) -> i32 {
    if n < 2 {
        1
    } else {
        fib(n - 1) + fib(n - 2)
    }
}

fn run_fib() {
    fib(FIB_ITER);
}

fn fib_single_float(n: f32) -> f32 {
    if n < 2f32 {
        1f32
    } else {
        fib_single_float(n - 1f32) + fib_single_float(n - 2f32)
    }
}

fn run_fib_single_float() {
    fib_single_float(FIB_ITER as f32);
}

fn fib_double_float(n: f64) -> f64 {
    if n < 2f64 {
        1f64
    } else {
        fib_double_float(n - 1f64) + fib_double_float(n - 2f64)
    }
}

fn run_fib_double_float() {
    fib_double_float(FIB_ITER as f64);
}

fn ackermann(m: i32, n: i32) -> i32 {
    if 0 == m {
        n + 1
    } else if 0 == n {
        ackermann(m - 1, 1)
    } else {
        ackermann(m - 1, ackermann(m, n - 1))
    }
}

fn run_ackermann() {
    ackermann(3, 11);
}

fn tak(x: i32, y: i32, z: i32) -> i32 {
    if !(y < x) {
        z
    } else {
        tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y))
    }
}

fn run_tak() {
    tak(18, 12, 6);
}

fn bench_string_concat(size: usize, runs: i32) -> () {
    for _ in 0..runs {
        let buflen: usize;
        let mut buf = String::new();
        for _ in 0..size {
            buf.push_str("hi there!");
        }
        buflen = buf.len();
        assert_eq!(buflen, size * ("hi there!".len()));
    }
}

fn bench_1d_arrays(size: usize, runs: i32) -> () {
    let mut ones: Vec<u16> = Vec::new();
    let mut twos: Vec<u16> = Vec::new();
    let mut threes: Vec<u16> = Vec::new();
    for _ in 0..size {
        ones.push(1);
        twos.push(2);
        threes.push(0);
    }
    for _ in 0..runs {
        for pos in 0..size {
            threes[pos] = ones[pos] + twos[pos];
        }
        for &elt in threes.iter() {
            assert_eq!(elt, 3);
        }
    }
}

fn run_bench_1d_arrays() {
    bench_1d_arrays(100000, 10);
    //bench_1d_arrays_100000(10);
}

fn bench_2d_arrays(size: usize, runs: u32) {
    let mut ones: Vec<Vec<u16>> = Vec::new();
    let mut twos: Vec<Vec<u16>> = Vec::new();
    let mut threes: Vec<Vec<u16>> = Vec::new();
    for _ in 0..size {
        let mut iones: Vec<u16> = Vec::new();
        let mut itwos: Vec<u16> = Vec::new();
        let mut ithrees: Vec<u16> = Vec::new();
        for _ in 0..size {
            iones.push(1);
            itwos.push(2);
            ithrees.push(0);
        }
        ones.push(iones);
        twos.push(itwos);
        threes.push(ithrees);
    }
    for _ in 0..runs {
        for i in 0..size {
            for j in 0..size {
                threes[i][j] = ones[i][j] + twos[i][j];
            }
        }
        let elt: u16 = threes[3][3];
        assert!(elt == 3, "The assertion {} == 3 failed.", elt);
    }
}

fn run_bench_2d_arrays() {
    bench_2d_arrays(2000, 10);
}

fn listn(n: usize) -> Vec<usize> {
    vec![0; n]
}

fn shorterp(x: Vec<usize>, y: Vec<usize>) -> bool {
    y.len() > 0 && (x.len() == 0 || shorterp(x[1..].to_vec(), y[1..].to_vec()))
}

fn mas(x: Vec<usize>, y: Vec<usize>, z: Vec<usize>) -> Vec<usize> {
    if !shorterp(y.to_vec(), x.to_vec()) {
        z
    } else {
        mas(
            mas(x[1..].to_vec(), y.to_vec(), z.to_vec()),
            mas(y[1..].to_vec(), z.to_vec(), x.to_vec()),
            mas(z[1..].to_vec(), x.to_vec(), y.to_vec()),
        )
    }
}

fn run_takl() {
    mas(listn(18), listn(12), listn(6));
}

fn crc_division_step(bit: u8, rmdr: i64, poly: i64, msb_mask: i64) -> i64 {
    // Shift in the bit into the LSB of the register (rmdr)
    let new_rmdr: i64 = bit as i64 | (rmdr * 2);
    // Divide by the polynomial, and return the new remainder
    if 0 == (msb_mask & new_rmdr) {
        new_rmdr
    } else {
        new_rmdr ^ poly
    }
}

fn integer_length(n: i64) -> usize {
    (if n < 0 { -n } else { n + 1 } as f64).log2().ceil() as usize
}

fn compute_adjustment(poly: i64, n: i64) -> i64 {
    // Precompute X^(n-1) mod poly
    let poly_len_mask: i64 = 1i64 << (integer_length(poly) - 1);
    let mut rmdr: i64 = crc_division_step(1, 0, poly, poly_len_mask);
    for _ in 0..n - 1 {
        rmdr = crc_division_step(0, rmdr, poly, poly_len_mask);
    }
    rmdr
}

fn calculate_crc40(iterations: usize) -> i64 {
    let crc_poly: i64 = 1099587256329;
    let len: i64 = 3014633;
    let mut answer: i64 = 0;
    for _ in 0..iterations {
        answer = compute_adjustment(crc_poly, len);
    }
    answer
}

fn run_crc40() {
    const CRC40: i64 = 549793628164;
    assert_eq!(CRC40, calculate_crc40(10));
}

fn main() {
    println!("\n(\"Rust {}\"", "1.56.0");
    run("CRC40".to_string(), 2, run_crc40);
    run("FIB".to_string(), 50, run_fib);
    run("FIB-SINGLE-FLOAT".to_string(), 50, run_fib_single_float);
    run("FIB-DOUBLE-FLOAT".to_string(), 50, run_fib_double_float);
    run("ACKERMANN".to_string(), 1, run_ackermann);
    run("CRC40".to_string(), 2, run_crc40);
    run("1D-ARRAYS".to_string(), 1, run_bench_1d_arrays);
    run("2D-ARRAYS".to_string(), 1, run_bench_2d_arrays);
    // run("FIB-RATIO".to_string(), 500, run_fib_ratio);
    run("TAK".to_string(), 1000, run_tak);
    run("TAKL".to_string(), 150, run_takl);
    // run("FACTORIAL".to_string(), 1000, run_factorial);
    run("STRING-CONCAT".to_string(), 1, || -> () {
        bench_string_concat(1000000, 100)
    });
    println!(")\n");
}
