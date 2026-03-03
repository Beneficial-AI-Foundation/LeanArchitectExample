import Architect
import Example.F2

@[blueprint "thm:double-succ"
  (statement := /-- Doubling a successor: $\text{double}(n+1) = \text{double}(n) + 2$. -/)]
theorem double_succ (n : Nat) : double (n + 1) = double n + 2 := by
  unfold double; omega

@[blueprint "thm:double-pos"
  (statement := /-- Doubling a positive number is positive. -/)]
theorem double_pos (n : Nat) (h : n > 0) : double n > 0 := by
  unfold double; omega
