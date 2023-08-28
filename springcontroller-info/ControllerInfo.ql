// filename, controller path (if any), method path (with mapping annotaion), HTTP method, path var, req param, req body, headers, resp body
/**
 * @id java/springcontroller-info
 * @kind problem
 */
import java
import semmle.code.java.frameworks.spring.SpringController

string getMethodPathVariableParams(SpringRequestMappingMethod m) {
  if
    m.getARequestParameter().getAnAnnotation().getType().hasName("PathVariable")
  then
  exists(SpringRequestMappingParameter p |
      p = m.getARequestParameter() and
      p.getAnAnnotation().getType().hasName("PathVariable")  
    and result = p.getName())
  else result = ""
}

string getMethodRequestParams(SpringRequestMappingMethod m) {
  if
    m.getARequestParameter().getAnAnnotation().getType().hasName("RequestParam")
  then
    exists(SpringRequestMappingParameter p |
      p = m.getARequestParameter() and
      p.getAnAnnotation().getType().hasName("RequestParam") and
      result = p.getName()
    )
  else result = ""
}

string getMethodRequestBodyParams(SpringRequestMappingMethod m) {
  if
    m.getARequestParameter().getAnAnnotation().getType().hasName("RequestBody")
  then
    exists(SpringRequestMappingParameter p, Class rb |
      p = m.getARequestParameter() and
      p.getAnAnnotation().getType().hasName("RequestBody") and
      rb.getName() = p.getType().toString() and
      result = concat(rb.getAField().getName(),",")
    )
  else result = ""
}

string getMappedPath(Annotatable o) {
  if o.getAnAnnotation().getType() instanceof SpringRequestMappingAnnotationType
  then
    exists(Annotation a |
      a = o.getAnAnnotation() and
      a.getType() instanceof SpringRequestMappingAnnotationType and
      (
        result = a.getAStringArrayValue(["value", "path"])
        or
        not exists(any(a.getAStringArrayValue(["value", "path"]))) and result = ""
      )
    )
  else result = ""
}

string getMethodType(SpringRequestMappingMethod m) {
  exists(Annotation a, string t |
    a = m.getAnAnnotation() and
    t = a.getType().toString() and
    (
      (
        a.getValue(["method"]).toString().matches("%GET") or
        a.getValue(["method"]).getAChildExpr().toString().matches("%GET") or
        t = "GetMapping"
      ) and
      result = "GET"
      or
      (
        a.getValue(["method"]).toString().matches("%POST") or
        a.getValue(["method"]).getAChildExpr().toString().matches("%POST") or
        t = "PostMapping"
      ) and
      result = "POST"
      or
      (
        a.getValue(["method"]).toString().matches("%PUT") or
        a.getValue(["method"]).getAChildExpr().toString().matches("%PUT") or
        t = "PutMapping"
      ) and
      result = "PUT"
      or
      (
        a.getValue(["method"]).toString().matches("%DELETE") or
        a.getValue(["method"]).getAChildExpr().toString().matches("%DELETE") or
        t = "DeleteMapping"
      ) and
      result = "DELETE"
      or
      (t = "RequestMapping" and not exists(any(a.getValue(["method"])))) and
      result = "GET/POST"
    )
  )
}

from SpringRequestMappingMethod requestMappingMethod, SpringController controller
where requestMappingMethod = controller.getAMethod()
select controller,
  // controller.getFile().getAbsolutePath() as file,
  requestMappingMethod,
  getMappedPath(controller) as controllerPath, getMappedPath(requestMappingMethod) as methodPath,
  getMethodType(requestMappingMethod) as methodType,
  concat(getMethodPathVariableParams(requestMappingMethod), ",") as pathVariable,
  concat(getMethodRequestParams(requestMappingMethod), ",") as requestParam,
  concat(getMethodRequestBodyParams(requestMappingMethod), ",") as requestBodyParams
