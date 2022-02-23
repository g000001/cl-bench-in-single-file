using Printf

function bench_time(fctn, times, name)
    real_time = @elapsed for i = 1 : times
	fctn()
    end
    return name, real_time, real_time, 0, 0
end

function run_(name, times, fctn) 
    name, rt, ut, sys, consed = bench_time(fctn, times, name)
    @printf ";;; running #<benchmark %s for %s runs>\n" name times
    @printf "(\"%s\" %s %s %d %d)\n" name rt ut sys consed
end

const fib_iter = 25

function fact(n)
    if 0==n
        1
    else
        n * fact(n - 1)
    end
end

function run_factorial()
    fact(big(500))
end

function fib(n)
    if n < 2
        1
    else
        fib(n-1)+fib(n-2)
    end
end

function run_fib()
    fib(fib_iter)
end

function ackermann(m, n)
    if 0==m
        n+1
    elseif 0==n
        ackermann(m-1, 1)
    else
        ackermann(m-1, ackermann(m, n-1))
    end
end

function run_ackermann()
    ackermann(3, 11)
end

function tak(x, y, z)
    if !(y < x)
        z
    else
        tak(tak(x-1, y, z),
            tak(y-1, z, x),
            tak(z-1, x, y))
    end
end

function run_tak()
    tak(18, 12, 6)
end

function bench_1d_arrays(size, runs) 
    ones = fill(UInt16(1), size)
    twos = fill(UInt16(2), size)
    threes = Vector{UInt16}(undef, size)
    for run = 1 : runs
	for pos = 1 : size
	    threes[pos] = ones[pos] + twos[pos]
	end
	for elt = threes
	    @assert elt == 3 @sprintf "The assertion %s == 3 failed." elt
        end
    end
end

function run_bench_1d_arrays() 
    bench_1d_arrays(100000, 10)
end

function bench_2d_arrays(size, runs) 
    ones = fill(UInt16(1), (size, size))
    twos = fill(UInt16(2), (size, size))
    threes = Array{UInt16, 2}(undef, (size, size))
    for run = 1 : runs
        for i = 1 : size
            for j = 1 : size
                threes[i, j] = ones[i, j] + twos[i, j]
            end
        end
        for i = 1 : size
            for j = 1 : size
                elt = threes[i, j]
                @assert elt == 3 @sprintf "The assertion %s == 3 failed." elt
            end
        end
    end
end

function run_bench_2d_arrays() 
    bench_2d_arrays(2000, 10)
end

function fib_single_float(n)
    if n < Float32(2)
        Float32(1)
    else 
	fib_single_float(n-Float32(1)) + fib_single_float(n-Float32(2))
    end
end

function run_fib_single_float() 
    fib_single_float(Float32(fib_iter))
end

function fib_double_float(n)
    if n < Float64(2)
	Float64(1)
    else 
        fib_double_float(n-Float64(1)) + fib_double_float(n-Float64(2))
    end
end

function run_fib_double_float() 
    fib_double_float(Float64(fib_iter))
endn

function fib_ratio(n)
    function fr(n)
        if n == 1
            1
        else
            1 + Rational{BigInt}(1//fr(n-1))
        end
    end
    numerator(fr(n))
end

function run_fib_ratio()
    fib_ratio(150)
end

function listn(n)
    fill(0, n)
end

function shorterp(x, y)
    0<length(y) && (0==length(x) || shorterp(x[2:end], y[2:end]))
end   

function mas(x, y, z)
    if !shorterp(y, x)
        z
    else
        mas(mas(x[2:end], y, z),
            mas(y[2:end], z, x),
            mas(z[2:end], x, y))
    end
end

function run_takl()
    l18 = listn(18)
    l12 = listn(12)
    l6 = listn(6)
    mas(l18, l12, l6)
end

function bench_string_concat(size, runs) 
    for _ = 1 : runs
        buf = IOBuffer()
        for _ = 1 : size
            write(buf, "hi there!")
        end
        buflen = length(String(take!(buf)))
        # buflen = length(repeat("hi there!", size)) # much faster
        @assert buflen == length("hi there!")*size
                @sprintf "buflen:%s == size*runs:%s" buflen length("hi there!")*size
    end
end

function crc_division_step(bit, rmdr, poly, msb_mask)
    # Shift in the bit into the LSB of the register (rmdr)
    new_rmdr = Int64(bit | (rmdr * 2))
    # Divide by the polynomial, and return the new remainder
    if (0 == (msb_mask & new_rmdr)) 
        new_rmdr
    else 
        xor(new_rmdr, poly)
    end
end

function integer_length(n)
    if n < 0
        n = -n
    else 
        n += 1
    end
    ans = log2(n)
    Int64(ceil(ans))
end

function compute_adjustment(poly,n)
    # Precompute X^(n-1) mod poly
    poly_len_mask = 1 << (integer_length(poly) - 1)
    rmdr = crc_division_step(1, 0, poly, poly_len_mask)
    for k = 1 : n-1
        rmdr = crc_division_step(0, rmdr, poly, poly_len_mask)
    end
    rmdr
end

function calculate_crc40(iterations) 
    crc_poly = 1099587256329
    len = 3014633
    answer = 0
    for k = 1 : iterations
        answer = compute_adjustment(crc_poly, len)
    end
  return answer;
end

function run_crc40()
    calculate_crc40(10) #549793628164
end

function main() 
    @printf "\n(\"Julia %s\"\n" VERSION
    run_("CRC40", 2, run_crc40)
    run_("1D-ARRAYS", 1, run_bench_1d_arrays)
    run_("2D-ARRAYS", 1, run_bench_2d_arrays)
    run_("FIB", 50, run_fib)
    run_("FIB-RATIO", 500, run_fib_ratio)
    run_("FIB-SINGLE-FLOAT", 50, run_fib_single_float)
    run_("FIB-DOUBLE-FLOAT", 50, run_fib_double_float)
    run_("ACKERMANN", 1, run_ackermann)
    run_("TAK", 1000, run_tak)
    run_("TAKL", 150, run_takl)
    run_("FACTORIAL", 1000, run_factorial)
    run_("STRING-CONCAT", 1, (() -> bench_string_concat(1000000, 100)))
    @printf ")\n"
end

#main()

