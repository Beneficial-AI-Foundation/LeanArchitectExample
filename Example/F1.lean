import Example.F2

theorem double_succ (n : Nat) : double (n + 1) = double n + 2 := by
  unfold double; omega

theorem double_pos (n : Nat) (h : n > 0) : double n > 0 := by
  unfold double; omega
