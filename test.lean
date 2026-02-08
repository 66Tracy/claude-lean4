-- test.lean
-- Lean4 basic test


def add (x y : Nat) : Nat := x + y
theorem add_comm (a b : Nat) : a + b = b + a := by
  rw [Nat.add_comm]

#eval println! s!"2 + 3 = {add 2 3}"
#check add
#check add_comm

def myList : List Nat := [1, 2, 3, 4, 5]

structure Point where
  x : Float
  y : Float
  deriving Repr

def origin : Point := { x := 0.0, y := 0.0 }
def myPoint : Point := { x := 3.5, y := 2.7 }

#eval origin
#eval myPoint

def factorial : Nat -> Nat
  | 0 => 1
  | n + 1 => (n + 1) * factorial n

#eval factorial 5

theorem zero_add (n : Nat) : 0 + n = n := by
  simp

#check zero_add