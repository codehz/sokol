import std/macros

var inited {.compileTime.}: bool
var ginits {.compileTime.}: seq[NimNode]

macro delayinit*(name: untyped, expr: typed) =
  let vtype = getTypeInst(expr)
  result = quote do:
    var `name`: `vtype`
  ginits.add quote do:
    `name` = `expr`

macro delayinit*(name: untyped, etype: typed, expr: untyped) =
  result = quote do:
    var `name`: `etype`
  ginits.add quote do:
    `expr`

macro doinit*() =
  if inited:
    error("do not call doinit twice")
  inited = true
  result = newStmtList()
  for f in ginits:
    result.add f
