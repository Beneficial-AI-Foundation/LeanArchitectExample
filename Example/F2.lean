import Architect

@[blueprint "def:double"
  (statement := /-- Doubles a natural number by adding it to itself. -/)]
def double (n : Nat) : Nat := n + n

@[blueprint "thm:double-zero"
  (statement := /-- Doubling zero yields zero. -/)]
theorem double_zero : double 0 = 0 := by rfl
