
load v_gainTable
modulationRef=60;
ibias=2;
yfov=50    
lutOUT=genTXPWRlut(v_gainTable,modulationRef,ibias,yfov,480,0,0);
plot(0:64,lutOUT);set(gca,'ylim',[-6 0]);