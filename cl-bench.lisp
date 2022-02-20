(in-package cl-user)


;;; https://www.cliki.net/cl-bench


(declaim (optimize (speed 3) (safety 0) (debug 0) (compilation-speed 0)))


;; a generic timing function, that depends on GET-INTERNAL-RUN-TIME
;; and GET-INTERNAL-REAL-TIME returning sensible results. If a version
;; was defined in sysdep/setup-<impl>, we use that instead
(defun bench-time (fun times name)
  (declare (ignore name))
  (let (before-real after-real before-user after-user)
    (setq before-user (get-internal-run-time))
    (setq before-real (get-internal-real-time))
    (dotimes (i times)
      (funcall fun))
    (setq after-user (get-internal-run-time))
    (setq after-real (get-internal-real-time))
    ;; return real user sys consed
    (values (/ (- after-real before-real) internal-time-units-per-second)
            (/ (- after-user before-user) internal-time-units-per-second)
            0 0)))


(defun run (name times fctn)
  (multiple-value-bind (real-time user-time sys consed)
                       (bench-time fctn times name)
    (format T "~&;;; running #<benchmark ~A for ~A runs>~%" name times)
    (format T "~&~S~%" (list name (float real-time) (float user-time) sys consed))))


(defconstant fib-iter 25)


(defun factorial (n)
  (declare (type integer n))
  (if (zerop n) 1
      (* n (factorial (1- n)))))


(defun run-factorial ()
  (declare (inline factorial))
  (factorial 500))


(defun fib (n)
  (declare (type integer n))
  (if (< n 2) 1 (+ (fib (- n 1)) (fib (- n 2)))))


(defun run-fib ()
  (declare (inline fib))
  (fib fib-iter))


(defun fib-single-float (n)
  (declare (single-float n))
  (if (< n 2s0)
      n
      (+ (fib-single-float (- n 1s0))
         (fib-single-float (- n 2s0)))))


(defun run-fib-single-float ()
  (declare (inline fib-single-float))
  (fib-single-float (float fib-iter 0s0)))


(defun fib-double-float (n)
  (declare (double-float n))
  (if (< n 2d0)
      n
      (+ (fib-double-float (- n 1d0))
         (fib-double-float (- n 2d0)))))


(defun run-fib-double-float ()
  (declare (inline fib-double-float))
  (fib-double-float (float fib-iter 0d0)))


(defun fib-ratio (n)
  (declare (type integer n))
  (labels ((fr (n)
             (if (= n 1) 1
                 (1+ (/ (fr (- n 1)))))))
    (numerator (fr n))))


(defun run-fib-ratio ()
  (declare (inline fib-ratio))
  (fib-ratio 150))


;; The Ackermann function is the simplest example of a well-defined total
;; function which is computable but not primitive recursive, providing a
;; counterexample to the belief in the early 1900s that every computable
;; function was also primitive recursive (Dtzel 1991). It grows faster
;; than an exponential function, or even a multiple exponential function. 
#+lispworks (setq sys:*stack-overflow-behaviour* nil)

(defun ackermann (m n)
  (declare (type integer m n))
  #+lispworks (declare (optimize (speed 3)
                                 (debug 0)
                                 (safety 1) ;it should be safety > 0; optimization bug?
                                 (space 0)
                                 ))
  (cond
    ((zerop m) (1+ n))
    ((zerop n) (ackermann (1- m) 1))
    (t (ackermann (1- m) (ackermann m (1- n))))))


(defun run-ackermann ()
  (ackermann 3 11))


;;; TAK -- A vanilla version of the TAKeuchi function and one with tail recursion
;;; removed.

(defun tak (x y z)
  (declare (fixnum x y z))
  (if (not (< y x))
      z
      (tak (tak (the fixnum (1- x)) y z)
	   (tak (the fixnum (1- y)) z x)
	   (tak (the fixnum (1- z)) x y))))


(defun run-tak ()
  (tak 18 12 6))


;;; TAKL -- The TAKeuchi function using lists as counters.

(defun listn (n)
  (if (not (= 0 (the fixnum n)))
      (cons n (listn (1- n)))))


(defun shorterp (x y)
  (declare (list x y))
  (and y (or (null x)
	     (shorterp (cdr x)
		       (cdr y)))))


(defun mas (x y z)
  (declare (list x y z))
  (if (not (shorterp y x))
      z
      (mas (mas (cdr x)
		 y z)
	    (mas (cdr y)
		 z x)
	    (mas (cdr z)
		 x y))))


(defun run-takl ()
  (let ((l18 (listn 18.))
        (l12 (listn 12.))
        (l6 (listn 6.)))
    (mas l18 l12 l6)))


(defun bench-1d-arrays (&optional (size 100000) (runs 10))
  (declare (fixnum size))
  (let ((ones (make-array size :element-type '(integer 0 1000) :initial-element 1))
        (twos (make-array size :element-type '(integer 0 1000) :initial-element 2))
        (threes (make-array size :element-type '(integer 0 2000))))
    (dotimes (runs runs)
      (dotimes (pos size)
        (setf (aref threes pos) (+ (aref ones pos) (aref twos pos))))
      (assert (null (search (list 4 5 6) threes)))))
  (values))


(defun run-bench-1d-arrays ()
  (bench-1d-arrays 100000 10))


(defun bench-2d-arrays (&optional (size 2000) (runs 10))
  (declare (fixnum size))
  (let ((ones (make-array (list size size) :element-type '(integer 0 1000) :initial-element 1))
        (twos (make-array (list size size) :element-type '(integer 0 1000) :initial-element 2))
        (threes (make-array (list size size) :element-type '(integer 0 2000))))
    (dotimes (runs runs)
      (dotimes (i size)
        (dotimes (j size)
          (setf (aref threes i j)
                (+ (aref ones i j) (aref twos i j)))))
      (assert (eql 3 (aref threes 3 3)))))
  (values))


(defun run-bench-2d-arrays ()
  (bench-2d-arrays 2000 10))


;; certain implementations such as OpenMCL have an array (and thus
;; string) length limit of (expt 2 24), so don't try this on humungous
;; sizes
(defun bench-string-concat (&optional (size 1000000) (runs 100))
  (declare (fixnum size))
  (dotimes (runs runs)
    (let ((len (length
                (with-output-to-string (string)
                  (dotimes (i size)
                    (write-sequence "hi there!" string))))))
      (assert (eql len (* size (length "hi there!")))))
    (values)))


;;(declaim (inline crc-division-step))

(defun crc-division-step (bit rmdr poly msb-mask)
  (declare (type (signed-byte 56) rmdr poly msb-mask)
	   (type bit bit))
  ;; Shift in the bit into the LSB of the register (rmdr)
  (let ((new-rmdr (logior bit (* rmdr 2))))
    ;; Divide by the polynomial, and return the new remainder
    (if (zerop (logand msb-mask new-rmdr))
	new-rmdr
	(logxor new-rmdr poly))))


(defun compute-adjustment (poly n)
  (declare (type (signed-byte 56) poly)
	   (fixnum n))
  ;; Precompute X^(n-1) mod poly
  (let* ((poly-len-mask (ash 1 (1- (integer-length poly))))
	 (rmdr (crc-division-step 1 0 poly poly-len-mask)))
    (dotimes (k (- n 1))
      (setf rmdr (crc-division-step 0 rmdr poly poly-len-mask)))
    rmdr))


(defun calculate-crc40 (iterations)
  (declare (fixnum iterations))
  (let ((crc-poly 1099587256329)
	(len 3014633)
	(answer 0))
    (dotimes (k iterations)
      (declare (fixnum k))
      (setf answer (compute-adjustment crc-poly len)))
    answer))


(defun run-crc40 ()
  (calculate-crc40 10))


(defun halt ()
  #+lispworks (quit)
  #+sbcl (exit))


(defun main ()
  (format T "~&(~S" (concatenate 'string
                                 (lisp-implementation-type)
                                 " "
                                 (lisp-implementation-version)))
  (run "CRC40" 2 #'run-crc40)
  (run "1D-ARRAYS" 1 #'run-bench-1d-arrays)
  (run "2D-ARRAYS" 1 #'run-bench-2d-arrays)
  (run "FIB" 50 #'run-fib)
  (run "FIB-RATIO" 500 #'run-fib-ratio)
  (run "FIB-SINGLE-FLOAT" 50 #'run-fib-single-float)
  (run "FIB-DOUBLE-FLOAT" 50 #'run-fib-double-float)
  #-(or clisp) (run "ACKERMANN" 1 #'run-ackermann)
  (run "TAK" 1000 #'run-tak)
  (run "TAKL" 150 #'run-takl)
  (run "FACTORIAL" 1000 #'run-factorial)
  #-(or clisp allegro-cl-express) (run "STRING-CONCAT" 1 (lambda () (bench-string-concat 1000000 100)))
  (format T ")~%")
  (halt))


;;(main)


;;; *EOF*
