import macros, os
import typetraits
import ropes
import astalgo
import tables
import semdata
import sigmatch

let traceFile = os.getEnv("tracelog")
var currentStack = newSeq[string]()

var savedVars* = initTable[string,string]()

proc spaces(i: int): string =
  result = newString(i)
  for c in result.mitems(): c = ' '

proc flagsToStr[T](flags: set[T]): Rope =
  if flags == {}:
    result = rope("[]")
  else:
    result = nil
    for x in items(flags):
      if result != nil: add(result, ", ")
      add(result, makeYamlString($x))
    result = "[" & result & "]"

proc getRepr*[T](v: T, i: int, c: PContext): string =
  when compiles(v == nil):
    if v == nil:
      return "nil"
  when v is int:
    block:
      return "(int) " & $v
  when compiles(v is TCandidateState):
    when v is TCandidateState:
      block:
        return "(TCandidateState) " & $v
  when v is seq or v is TTypeSeq:
    block:
      result = "["
      for s in v:
        result &= getRepr(s, i+2, c) & ", "
      return result & "]"
  when v is PType:
    block:
      return "(PType)??? kind = " & $v.kind & ", flags = " & $v.flags &
          ", n = " & getRepr(v.n, i+2, c) & ", sym = " & getRepr(v.sym, i+2, c) &
          ", sons = " & getRepr(v.sons, i+2, c)
      #return $debugType(v, 15)
  when v is TIdTable:
    block:
      result = "(TIdTable) counter = " & $v.counter & ":\n" & spaces(i+2)
      for el in v.data:
        if el.key != nil:
          result &= getRepr(el.key, i+2, c) & ": " & getRepr(el.val, i+2, c) & ", "
      return result
  when v is PSym:
    block:
      if v.kind == skUnknown:
        return "(PSym) skUnknown"
      else:
        return "(PSym) " & v.name.s & "_" & $v.id & ":" & " " &
          $flagsToStr(v.flags) & " " & $flagsToStr(v.loc.flags) & " " &
          $lineInfoToStr(v.info) & " " & $v.kind
  when v is PNode:
    block:
      #return "PNode???"
      return "(PNode) " & ($debugTree(v, 0, 15)).replace("\n").
          replace("                  ", " ").replace("      ", " ")
  when compiles(v is TCandidate):
    when v is TCandidate:
      block:
        result = "(TCandidate) "
        for kk, vv in v.fieldPairs():
          result &= "\n" & spaces(i+2) & "+" & kk & ": " & getRepr(vv, i+4, c)
        return result #"TCandidate???"
  when v is PContext:
    block:
      result = "(PContext)??? generics = " & getRepr(v.generics, i+2, c)
      result &= ", inTypeClass = " & $v.inTypeClass
      return result
  when v is TInstantiationPair:
    block:
      return getRepr(v.genericSym, i+2, c) & " -> {" &
          getRepr(v.inst.sym, i+2, c) & ", " &
          getRepr(v.inst.concreteTypes, i+2, c) & "}"
  when v is PIdObj:
    block:
      if c != nil:
        result = ""
        #for s in c.signatures: #topLevelScope.symbols: #currentScope.symbols:
        #  block: #s.id != v.id:
            #return "(PIdObj) s = " & getRepr(s, i+2, c)
            #result &= "(PIdObj) s = " & $s.id & " ?= " & $v.id
        return "(PIdObj) " & $v[]
  when v is RootRef:
    block:
      return "(RootRef) " & $v[]#getRepr(v[], i+2, c)
  result = "???"

template logThis*(nodeRepr: string): stmt {.immediate.}=
  let locs = locals()
  var ignore = false
  when compiles(n):
    when n is PNode:
      if n != nil and not (n.info ?? traceFile):
        ignore = true
  if traceFile != "" and not ignore:
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

    when compiles(c):
      when c is PContext:
        let myPContext = c
      else:
        let myPContext: PContext = nil
    else:
      let myPContext: PContext = nil

    for varName, varValue in locs.fieldPairs:
      block:
        let valueRepr = getRepr(varValue, stack.len, myPContext)
        if not savedVars.hasKey(varName) or savedVars[varName] != valueRepr:
          savedVars[varName] = valueRepr
          echo spaces(stack.len) & "+" & varName & ": " & valueRepr
    when compiles(msgs.gErrorCounter):
        let valueRepr = getRepr(msgs.gErrorCounter, stack.len, myPContext)
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

