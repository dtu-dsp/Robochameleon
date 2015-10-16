function tf = inherits_from(obj,className)

tf = any(strcmp(className,superclasses(obj)));
