# nimTracelog

I developed this tool to debug the Nim compiler. Just copy *tracelog.nim* to Nim/compiler/ folder, and add ``{.trace.}`` macro to functions. For example in *semexpr.nim* just replace
```nim
proc semIs(c: PContext, n: PNode): PNode =
  ...
```
to
```nim
import tracelog
proc semIs(c: PContext, n: PNode): PNode {.trace.} =
  ...
```

After compiling the compiler with ``./koch boot``, you can enable this tool by running: ``tracelog=test.nim nim c -r test.nim`` where *test.nim* is an arbitrary file to compile.

The output contains all the stacktrace to your function:
```nim
nim.nim(115) nim
 nim.nim(71) handleCmdLine
  main.nim(253) mainCommand
   main.nim(64) commandCompileToC
    modules.nim(226) compileProject
     modules.nim(209) compileSystemModule
      modules.nim(172) compileModule
       passes.nim(203) processModule
        passes.nim(137) processTopLevelStmt
         sem.nim(461) myProcess
          sem.nim(433) semStmtAndGenerateGenerics
...
```
and also lists the variables and lines from the function:
```nim
                     +n: (PNode) {  "kind": "nkCommand",  "sons": [    { "kind": "nkIdent", "ident": "echo", "info": ["test.nim", 16, 0]    },    { "kind": "nkCall", "sons": [   {     "kind": "nkIdent",     "ident": "first",     "info": ["test.nim", 16, 5]   },   {     "kind": "nkPrefix",     "sons": [  {    "kind": "nkIdent",    "ident": "@",    "info": ["test.nim", 16, 11]  },  {    "kind": "nkBracket",    "sons": [      { "kind": "nkIntLit", "intVal": 10, "info": ["test.nim", 16, 13]      },      { "kind": "nkIntLit", "intVal": 11, "info": ["test.nim", 16, 16]      },      { "kind": "nkIntLit", "intVal": 12, "info": ["test.nim", 16, 19]      }    ],    "info": ["test.nim", 16, 12]  }     ],     "info": ["test.nim", 16, 11]   } ], "info": ["test.nim", 16, 10]    }  ],  "info": ["test.nim", 16, 5]}
                     |if m.magic in {mArrGet, mArrPut}:
                     |  m.state = csMatch
                     |  m.call = n
                     |  return
                     |var marker = initIntSet()
                     +marker: ???
                     |matchesAux(c, n, nOrig, m, marker)
                   sigmatch.nim(1795) matches
                    sigmatch.nim(1752) matchesAux
                     sigmatch.nim(1592) prepareOperand
                      semexprs.nim(26) semOperand
                       semexprs.nim(2342) semExpr
...
```

#tracelogsimple

The *tracelogsimple.nim* is a simplified version of *tracelog.nim*. You can use it in a regular (not compiler) nim program. For example:
```nim
import tracelogsimple
proc fib(n: int): int {.trace.} =
  if n < 2:
    return n
  result = fib(n-1) + fib(n-2)
  return result

echo fib(4)
```

Results:
```nim
fib.nim(8) fib
 tracelogsimple.nim(27) fib
   +n: (int) 4
   +result: (int) 0
   |if n < 2:
   |  return n
   |result = fib(n - 1) + fib(n - 2)
 fib.nim(5) fib
  tracelogsimple.nim(27) fib
    +n: (int) 3
    |if n < 2:
    |  return n
    |result = fib(n - 1) + fib(n - 2)
  fib.nim(5) fib
   tracelogsimple.nim(27) fib
     +n: (int) 2
     |if n < 2:
     |  return n
     |result = fib(n - 1) + fib(n - 2)
   fib.nim(5) fib
    tracelogsimple.nim(27) fib
      +n: (int) 1
      |if n < 2:
      |  return n
      +n: (int) 0
      |if n < 2:
      |  return n
   tracelogsimple.nim(27) fib
     +n: (int) 2
     +result: (int) 1
     |return result
     +n: (int) 1
     +result: (int) 0
     |if n < 2:
     |  return n
  tracelogsimple.nim(27) fib
    +n: (int) 3
    +result: (int) 2
    |return result
    +n: (int) 2
    +result: (int) 0
    |if n < 2:
    |  return n
    |result = fib(n - 1) + fib(n - 2)
  fib.nim(5) fib
   tracelogsimple.nim(27) fib
     +n: (int) 1
     |if n < 2:
     |  return n
     +n: (int) 0
     |if n < 2:
     |  return n
  tracelogsimple.nim(27) fib
    +n: (int) 2
    +result: (int) 1
    |return result
 tracelogsimple.nim(27) fib
   +n: (int) 4
   +result: (int) 3
   |return result
3
```
```
