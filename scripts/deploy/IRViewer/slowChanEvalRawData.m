function [vscope,vscopeFs,mirTicks] = slowChanEvalRawData(varargin)


FRAME_TIME = 1/60*1e9;



%%%%%%%%%%%%%%%%%%%
%varargin parser:
%%%%%%%%%%%%%%%%%%%

inp = inputParser;


inp.addOptional('fn_in','\\invcam270\Ohad\data\lidar\EXP\20150121\horse\030cm.bin' );


parse(inp,varargin{:});
arg = inp.Results;



[basedir, ~] = fileparts(arg.fn_in);

POCUslowChanIndx = 2;
POCUsyncChanIndx = 3;


%%%%%%%%%%%%%%
%work on basic data
%%%%%%%%%%%%%%
%%
[t,vm]=io.POC.importScopeDataWpolarity(arg.fn_in,POCUsyncChanIndx);
[~,vscope]=io.POC.importScopeDataWpolarity(arg.fn_in,POCUslowChanIndx);
% % if(arg.fn_in(end)=='n') %it's .bin
% %  [t,vm]=io.POC.importAgilentBin(arg.fn_in,POCUsyncChanIndx); %[timeVector, voltageVector]
% %  [~,vscope]=io.POC.importAgilentBin(arg.fn_in,POCUslowChanIndx);
% % else %it's .h5
% %  [~,~,vm]=io.POC.readScopeHDF5data(arg.fn_in,POCUsyncChanIndx);
% %  [~,dt,vscope]=io.POC.readScopeHDF5data(arg.fn_in,POCUslowChanIndx);
% %  t = (0:length(vscope)-1)*dt;
% % end

%%
t = t*1e9; %now in nsec
t=t-t(1);
dt = t(2)-t(1);
vscopeFs = 1/diff(t(1:2));
% vmC = harmonicSignalCleanup(Ts,vm);
N = 1e6;


%removes the end of the data that is bigger then the frame time
vp=[mean(vm(1:N)) std(vm(1:N))*2 max(vm)];
vthr = sum(vp)/2;
cext = crossing([],vm,vthr);
if(mod(cext,2)==1)
    error('bad sync channel');
end
i0=(round(mean(cext(1:2)))-1);
nlast = find(t>FRAME_TIME+i0*dt,1);
if( isempty(nlast) )
    nlast = length(t);
end
nlast = min(length(t),i0+nlast);


vscope=vscope(i0:nlast);
vm = vm(i0:nlast);

mirF = (maxind(abs(fft(vm(1:N)-mean(vm(1:N)))))/N*vscopeFs);
mirBW = 40e-3;
[b,a]=butter(3,(mirF+[-.5 .5]*mirBW)/(0.5*vscopeFs));
vmC = filter(b,a,vm);
vmC(1:round(vscopeFs/mirF))=nan;
% mirTicks= Utils.getPulseTimes(Tfst,vmC);

mirTicks= getPulseTimesFAST(vmC,dt);
end

function c = getPulseTimesFAST(v,dt)
v = v(:);
ind = (diff(v(:)<0)==-1) | (diff(v(:)>0)==-1);
ind(end)=false;
ind =find(ind);
%remove first "high"
if(v(1)>0)
    ind(1)=[];
end
y0 = v(ind);
y1 = v(ind+1);
x0 =(ind-1)*dt;

x=-y0*dt./(y1-y0)+x0;
n = length(x);
x = x(1:n-mod(n,2));
x = reshape(x,2,[]);
d=median(diff(x));
c = mean(x)-d/2;

end
