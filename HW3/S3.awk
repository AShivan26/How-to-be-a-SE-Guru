BEGIN{FS=","}
NR==1{for(i=1;i<=NF;i++)H[i]=$i;next}
{for(i=1;i<=NF;i++) if(!(i in F))F[i]=$i; else if($i!=F[i])V[i]=1}
END{for(i=1;i<=length(H);i++) if(!V[i]) print H[i]}
