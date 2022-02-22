package main

import (
	"fmt"
	"math"
	"math/big"
	"runtime"
	"strings"
	"time"
)

func bench_1d_arrays(size int, runs int) {
	ones := make([]uint16, size)
	twos := make([]uint16, size)
	threes := make([]uint16, size)
	for i := 0; i < size; i++ {
		ones[i] = 1
		twos[i] = 2
	}
	for run := 0; run < runs; run++ {
		for pos := 0; pos < size; pos++ {
			threes[pos] = ones[pos] + twos[pos]
		}
		for _, elt := range threes {
			if elt != 3 {
				fmt.Printf("The assertion %#v == 3 failed.", elt)
				return
			}
		}
	}
}

func run_bench_1d_arrays() {
	bench_1d_arrays(100000, 10)
}

func bench_2d_arrays(size int, runs int) {
	ones := make([][]uint16, size)
	twos := make([][]uint16, size)
	threes := make([][]uint16, size)
	for i := 0; i < size; i++ {
		ones[i] = make([]uint16, size)
		twos[i] = make([]uint16, size)
		for j := 0; j < size; j++ {
			ones[i][j] = 1
			twos[i][j] = 2
		}
	}
	for run := 0; run < runs; run++ {
		for i := 0; i < size; i++ {
			threes[i] = make([]uint16, size)
			for j := 0; j < size; j++ {
				threes[i][j] = ones[i][j] + twos[i][j]
			}
		}
		for i := 0; i < size; i++ {
			for j := 0; j < size; j++ {
				elt := threes[i][j]
				if elt != 3 {
					fmt.Printf("The assertion %#v == 3 failed.", elt)
					return
				}
			}
		}
	}
}

func run_bench_2d_arrays() {
	bench_2d_arrays(2000, 10)
}

const (
	fib_iter = 25
)

func fib(n int) int {
	if n < 2 {
		return 1
	} else {
		return fib(n-1) + fib(n-2)
	}
}

func run_fib() {
	fib(fib_iter)
}

func fib_single_float(n float32) float32 {
	if n < 2 {
		return 1
	} else {
		return fib_single_float(n-1) + fib_single_float(n-2)
	}
}

func run_fib_single_float() {
	fib_single_float(float32(fib_iter))
}

func fib_double_float(n float64) float64 {
	if n < 2 {
		return 1
	} else {
		return fib_double_float(n-1) + fib_double_float(n-2)
	}
}

func run_fib_double_float() {
	fib_double_float(float64(fib_iter))
}

func fr(n *big.Rat) *big.Rat {
	if n.Cmp(big.NewRat(1, 1)) == 0 {
		return big.NewRat(1, 1)
	} else {
		nd := fr(new(big.Rat).Sub(n, big.NewRat(1, 1)))
		dn := new(big.Rat).Inv(nd)
		return new(big.Rat).Add(dn, big.NewRat(1, 1))
	}
}

func fib_ratio(n int64) *big.Int {
	return fr(big.NewRat(n, 1)).Num()
}

func run_fib_ratio() {
	fib_ratio(150)
}

func bench_time(fctn func(), times int, name string) (string, float64, float64, int, int) {
	s := time.Now()
	for i := 0; i < times; i++ {
		fctn()
	}
	real := float64(time.Since(s).Milliseconds()) / float64(1000)
	user := float64(time.Since(s).Milliseconds()) / float64(1000)
	return name, real, user, 0, 0
}

func ackermann(m int, n int) int {
	if m == 0 {
		return n + 1
	} else if n == 0 {
		return ackermann(m-1, 1)
	} else {
		return ackermann(m-1, ackermann(m, n-1))
	}
}

func run_ackermann() {
	ackermann(3, 11)
}

func tak(x, y, z int) int {
	if !(y < x) {
		return z
	} else {
		return tak(tak(x-1, y, z),
			tak(y-1, z, x),
			tak(z-1, x, y))
	}
}

func run_tak() {
	tak(18, 12, 6)
}

func factorial(n *big.Int) *big.Int {
	if n.Cmp(big.NewInt(0)) == 0 {
		return big.NewInt(1)
	} else {
		return new(big.Int).Mul(n, factorial(new(big.Int).Sub(n, big.NewInt(1))))
	}
}

func run_factorial() {
	factorial(big.NewInt(500))
}

func iota(n int) []int {
	p := make([]int, n)
	for i := 0; i < n; i++ {
		p[i] = i
	}
	return p
}

func list_tail(x []int, n int) []int {
	return x[n:]
}

func revloop(x []int, n int, y []int) []int {
	if n == 0 {
		return y
	} else {
		for i := n; i > 0; i-- {
			y = append(y, x[i-1])
		}
		return y
	}
}

func listn(n int) []int {
	if !(n == 0) {
		return append(listn(n-1), n)
	} else {
		return make([]int, 0)
	}
}

func shorterp(x []int, y []int) bool {
	ans := len(y) > 0 && (len(x) == 0 || shorterp(x[1:], y[1:]))
	return ans
}

func mas(x []int, y []int, z []int) []int {
	if !(shorterp(y, x)) {
		return z
	} else {
		return mas(mas(x[1:], y, z),
			mas(y[1:], z, x),
			mas(z[1:], x, y))
	}
}

func run_takl() {
	mas(listn(18), listn(12), listn(6))
}

func bench_string_concat(size int, runs int) {
	for cnt := 0; cnt < runs; cnt++ {
		var buflen int
		// /*
		var buf strings.Builder
		for i := 0; i < size; i++ {
			buf.WriteString("hi there!")
		}
		buflen = len(buf.String())
		//fmt.Println(buflen)

		// buflen = len(strings.Repeat("hi there!", size))
		if buflen != size*len("hi there!") {
			fmt.Println("foo!!!")
		}
	}
}

func run(name string, times int, fctn func()) {
	name, rt, ut, sys, consed := bench_time(fctn, times, name)
	fmt.Printf(";;; running #<benchmark %s for %v runs>\n", name, times)
	fmt.Printf("(%#v %v %v %d %d)\n", name, rt, ut, sys, consed)
}

func integer_length(n int) int {
	if n < 0 {
		n = -n
	} else {
		n += 1
	}
	ans := math.Log2(float64(n))
	return int(math.Ceil(ans))
}

func crc_division_step(bit int, rmdr int, poly int, msb_mask int) int {
	// Shift in the bit into the LSB of the register (rmdr)
	new_rmdr := bit | (rmdr * 2)
	// Divide by the polynomial, and return the new remainder
	if 0 == (msb_mask & new_rmdr) {
		return new_rmdr
	} else {
		return new_rmdr ^ poly
	}
}

func compute_adjustment(poly int, n int) int {
	// Precompute X^(n-1) mod poly
	poly_len_mask := int(1) << (integer_length(poly) - 1)
	rmdr := crc_division_step(1, 0, poly, poly_len_mask)
	for k := 0; k < n-1; k++ {
		rmdr = crc_division_step(0, rmdr, poly, poly_len_mask)
	}
	return rmdr
}

func calculate_crc40(iterations int) int {
	crc_poly := 1099587256329
	len := 3014633
	answer := 0
	for k := 0; k < iterations; k++ {
		answer = compute_adjustment(crc_poly, len)
	}
	return answer
}

func run_crc40() {
	calculate_crc40(10)
}

func main() {
	fmt.Printf("(\"Go %s\"\n", runtime.Version()[2:])
	run("CRC40", 2, run_crc40)
	run("1D-ARRAYS", 1, run_bench_1d_arrays)
	run("2D-ARRAYS", 1, run_bench_2d_arrays)
	run("FIB", 50, run_fib)
	run("FIB-RATIO", 500, run_fib_ratio)
	run("FIB-SINGLE-FLOAT", 50, run_fib_single_float)
	run("FIB-DOUBLE-FLOAT", 50, run_fib_double_float)
	run("ACKERMANN", 1, run_ackermann)
	run("TAK", 1000, run_tak)
	run("TAKL", 150, run_takl)
	run("FACTORIAL", 1000, run_factorial)
	run("STRING-CONCAT", 1, func() { bench_string_concat(1000000, 100) })
	fmt.Println(")")
}
