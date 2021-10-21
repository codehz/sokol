{.experimental: "caseStmtMacros".}

import std/[macros, tables]

func equalNode(a, b: NimNode): NimNode =
  nnkInfix.newTree(bindSym "==", a, b)

func `and=`(base: var NimNode, expr: NimNode) =
  if expr == newLit true:
    return
  if base == newLit true:
    base = expr
  else:
    base = nnkInfix.newTree(bindSym "and", base, expr)

func `or=`(base: var NimNode, expr: NimNode) =
  if expr == newLit false:
    return
  if base == newLit false:
    base = expr
  else:
    base = nnkInfix.newTree(bindSym "or", base, expr)

const identlists = {nnkSym, nnkIdent}
const strlits = {nnkStrLit, nnkRStrLit, nnkTripleStrLit}
const intlits = {nnkCharLit..nnkUInt64Lit}
const floatlits = {nnkFloatLit..nnkFloat128Lit}
const simplenode = {nnkSym, nnkIdent, nnkCharLit..nnkNilLit}

func genInSet(node: NimNode, name: static string): NimNode =
  nnkInfix.newTree(
    bindSym "in",
    newDotExpr(node, bindSym "kind"),
    bindSym name
  )

func match(this, expr: NimNode, cache: var Table[string, NimNode]): NimNode =
  result = newLit true
  case expr.kind:
  of nnkAccQuoted:
    if expr.len == 1:
      cache[expr[0].strVal] = this
      result = genInSet(this, "simplenode")
    elif expr.len == 2:
      expr[1].expectIdent "*"
      cache[expr[0].strVal] = this
    else:
      error("invalid quote: " & repr expr)
  of identlists:
    result = genInSet(this, "identlists")
    result.and = equalNode(newDotExpr(this, bindSym "strVal"), newLit expr.strVal)
  of strlits:
    result = genInSet(this, "strlits")
    result.and = equalNode(newDotExpr(this, bindSym "strVal"), newLit expr.strVal)
  of intlits:
    result = genInSet(this, "intlits")
    result.and = equalNode(newDotExpr(this, bindSym "intVal"), newLit expr.intVal)
  of floatlits:
    result = genInSet(this, "floatlits")
    result.and = equalNode(newDotExpr(this, bindSym "floatVal"), newLit expr.floatVal)
  of nnkCallKinds:
    result = genInSet(this, "nnkCallKinds")
    result.and = equalNode(newDotExpr(this, bindSym "len"), newLit expr.len)
    for idx, item in expr.pairs:
      result.and = match(nnkBracketExpr.newTree(this, newLit idx), item, cache)
  else:
    result = equalNode(newDotExpr(this, bindSym "kind"), newLit expr.kind)
    result.and = equalNode(newDotExpr(this, bindSym "len"), newLit expr.len)
    for idx, item in expr.pairs:
      result.and = match(nnkBracketExpr.newTree(this, newLit idx), item, cache)

macro `case`*(stmt: NimNode): untyped =
  result = nnkIfStmt.newTree()
  let expr = stmt[0]
  let branches = stmt[1..^1]
  for branch in branches:
    if branch.len == 2:
      let body = branch[1]
      var cache: Table[string, NimNode]
      var generated = newLit false
      for cond in branch[0]:
        generated.or = match(expr, cond, cache)
      let ifbranch = nnkElifBranch.newTree(generated, newStmtList())
      for k, v in cache:
        ifbranch[1].add newLetStmt(ident k, v)
      ifbranch[1].add body
      result.add ifbranch
    else:
      result.add nnkElse.newTree(branch[0])
