proj=args[0];
params = [:];
for (p in args[1].tokenize(";")){
  def x=p.tokenize("=");
  params[x[0]]=x[1][1..-2];
}
try {id2ignore=args[2].toInteger();}
catch ( e ) {id2ignore=0;}

for (it in jenkins.model.Jenkins.instance.getItem(proj).builds)
{
  if (it.getResult() != null){continue;}
  if (it.getNumber() ==id2ignore){continue;}
  def all_ok = true
  for (p in params)
  {
    try {
      if (it.getBuildVariables()[p]!=params[p]){all_ok=false;}
    }
    catch ( e ) {all_ok=false;}
  }
  if (all_ok==false){continue;}
  println "JOB FOUND:"+proj+" "+it.getNumber()
  it.doStop();
}

