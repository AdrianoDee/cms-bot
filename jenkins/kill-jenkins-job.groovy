boolean isJobMatched(prams, data)
{
  def all_ok = true;
  for (p in params)
  {
    def cv="";
    try {
      cv = data[p.key];
      if (cv != p.value){all_ok=false;}
    }
    catch ( e ) {all_ok=false; println "    "+e;}
    if (all_ok){println "    Matched   : "+p;}
    else{println "    Unmatched : "+p+"("+cv+")"; break;}
  }
  if (all_ok){println "  Matched job";}
  return all_ok;
}

proj=args[0];
params = [:];
for (p in args[1].tokenize(";")){
  def x=p.tokenize("=");
  def v="";
  if (x[1]!=null){v=x[1];}
  params[x[0]]=v;
}
try {id2ignore=args[2].toInteger();}
catch ( e ) {id2ignore=0;}

println "Procject:"+proj;
println "Params:"+params

println "Checking jobs in queue";
def queue = jenkins.model.Jenkins.getInstance().getQueue();
def items = queue.getItems();
for (i=0;i<items.length;i++)
{
  if (items[i].task.getName()==proj)
  {
    data = [:]
    for (p in items[i].getParams().tokenize("\n")){
      def x=p.tokenize("=");
      if (! params.containsKey(x[0])){continue;}
      def v="";
      if (x[1]!=null){v=x[1];}
      data[x[0]]=v;
    }
    println "  Checking Jobs :"+data;
    if (! isJobMatched(params, data)) {continue;}
    queue.cancel(items[i].task);
    println "  Cancelled Job";
  }
}

println "Checking running jobs";
for (it in jenkins.model.Jenkins.instance.getItem(proj).builds)
{
  if (it.isInProgress() != true){continue;}
  if (it.getNumber() == id2ignore){continue;}
  println "  Checking job number: "+it.getNumber();
  if (! isJobMatched(params, it.getBuildVariables())) {continue;}
  it.doStop();
  println "  Stopped Job";
}

