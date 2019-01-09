/**
 * @name Use of string copy function in a condition
 * @description The return value for strcpy, strncpy, or related string copy
 *              functions have no reserved return value to indicate an error.
 *              Using them in a condition is likely to be a logic error.
 * @kind problem
 * @problem.severity error
 * @precision high
 * @id cpp/string-copy-return-value-as-boolean
 * @tags external/microsoft/C6324
 *       correctness
 */

import cpp
import semmle.code.cpp.dataflow.DataFlow

predicate isStringComparisonFunction(string functionName) {
  functionName = "strcpy" or
  functionName = "wcscpy" or
  functionName = "_mbscpy" or
  functionName = "strncpy" or
  functionName = "_strncpy_l" or
  functionName = "wcsncpy" or
  functionName = "_wcsncpy_l" or
  functionName = "_mbsncpy" or
  functionName = "_mbsncpy_l"
}

predicate isBoolean(Expr e1) {
  exists(Type t1 |
    t1 = e1.getType() and
    (t1.hasName("bool") or t1.hasName("BOOL") or t1.hasName("_Bool"))
  )
}

predicate isStringCopyCastedAsBoolean(FunctionCall func, Expr expr1, string msg) {
  DataFlow::localFlow(DataFlow::exprNode(func), DataFlow::exprNode(expr1)) and
  isBoolean(expr1.getConversion*()) and
  isStringComparisonFunction(func.getTarget().getQualifiedName()) and
  msg = "Return value of " + func.getTarget().getQualifiedName() + " used as Boolean."
}

predicate isStringCopyUsedInLogicalOperationOrCondition(FunctionCall func, Expr expr1, string msg) {
  isStringComparisonFunction(func.getTarget().getQualifiedName()) and
  (
    (
      (
        // it is being used in an equality or logical operation
        exists(EqualityOperation eop |
          eop = expr1 and
          func = eop.getAnOperand()
        )
        or
        exists(UnaryLogicalOperation ule |
          expr1 = ule and
          func = ule.getOperand()
        )
        or
        exists(BinaryLogicalOperation ble |
          expr1 = ble and
          func = ble.getAnOperand()
        )
      ) and
      msg = "Return value of " + func.getTarget().getQualifiedName() +
          " used in a logical operation."
    )
    or
    exists(ConditionalStmt condstmt |
      // or the string copy function is used directly as the conditional expression
      func = condstmt.getControllingExpr() and
      expr1 = func and
      msg = "Return value of " + func.getTarget().getQualifiedName() +
          " used directly in a conditional expression."
    )
  )
}

from FunctionCall func, Expr expr1, string msg
where
  (
    isStringCopyCastedAsBoolean(func, expr1, msg) and
    not isStringCopyUsedInLogicalOperationOrCondition(func, expr1, _)
  )
  or
  isStringCopyUsedInLogicalOperationOrCondition(func, expr1, msg)
select expr1, msg
