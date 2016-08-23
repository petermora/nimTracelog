import macros, os
import typetraits
import ropes
import tables
import strutils

var currentStack = newSeq[string]()

var savedVars* = initTable[string,string]()

proc spaces(i: int): string =
  result = newString(i)
  for c in result.mitems(): c = ' '

proc getRepr*[T](v: T, i: int): string =
  when compiles(v == nil):
    if v == nil:
      return "nil"
  when v is int:
    block:
      return "(int) " & $v
  result = "???"

template logThis*(nodeRepr: string): stmt {.immediate.}=
  let locs = locals()
  block:
    var stack = getStackTrace().split("\n")
    stack.delete 0
    for i in 0..<stack.len-1:
      var first = true
      var line = ""
      for c in stack[i].items:
        if c == ' ':
          if first: line &= " "
          first = false
        else:
          line &= c
      if i > currentStack.len - 1 or currentStack[i] != line:
        var savedVars = initTable[string,string]()
        while i <= currentStack.len - 1:
          currentStack.del i
        currentStack.add line
        echo spaces(i) & line

    for varName, varValue in locs.fieldPairs:
      block:
        let valueRepr = getRepr(varValue, stack.len)
        if not savedVars.hasKey(varName) or savedVars[varName] != valueRepr:
          savedVars[varName] = valueRepr
          echo spaces(stack.len) & "+" & varName & ": " & valueRepr
    when compiles(msgs.gErrorCounter):
        let valueRepr = getRepr(msgs.gErrorCounter, stack.len)
        if not savedVars.hasKey("msgs.gErrorCounter") or savedVars["msgs.gErrorCounter"] != valueRepr:
          savedVars["msgs.gErrorCounter"] = valueRepr
          echo spaces(stack.len) & "+" & "msgs.gErrorCounter" & ": " & valueRepr
    for r in nodeRepr.split("\n"):
      echo spaces(stack.len) & "|" & r

macro trace*(s: untyped): stmt =
  let n = s.body.len
  for i in 0..<n:
    s.body.add nil
  for i in 0..<n:
    let node = s.body[n-1-i]
    s.body[2*(n-1-i) + 1] = node
    s.body[2*(n-1-i)] = getAst(logThis(node.repr))
  result = s

