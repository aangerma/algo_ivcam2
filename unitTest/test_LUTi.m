%%
func = @(x) sin(pi/2*x);
N_BIT_LUT = 32; % OS: how many bits are we going OUT of the LUT with
N_BIT_IN = 5; %OS: How many bits we are going INto the LUT
N_LUT_BIN = 4; % OS: Number of bins in the LUT


tLUT = (0:N_LUT_BIN)/(N_LUT_BIN-1/(2^N_BIT_IN/N_LUT_BIN));

yLUT = func(tLUT);
lutobj = LUTi(uint64(yLUT*(2^N_BIT_LUT-1)),N_BIT_LUT);


tQ =(0:2^N_BIT_IN-1)'/(2^N_BIT_IN-1);


y_hat = double(lutobj.at(uint64(tQ*(2^N_BIT_IN-1)),N_BIT_IN))/(2^N_BIT_LUT-1);
y_grt = func(tQ);

subplot(211)
plot(tLUT,yLUT,'p-',tQ,y_hat,'o-',tQ,y_grt,'s-','markersize',10)
lutobj.memsizeKB();
subplot(212)
plot(abs(y_grt-y_hat))

%%

%%
func = @(x) 8*x;
N_BIT_LUT = 8; % OS: how many bits are we going OUT of the LUT with
N_BIT_IN = 5; %OS: How many bits we are going INto the LUT
N_LUT_BIN = 4; % OS: Number of bins in the LUT

t = uint64(linspace(0,2^N_BIT_IN-1,N_LUT_BIN+1));

y = uint64(func(t));

lutobj = LUTi(y,N_BIT_LUT);


tQ = uint64(0:2^N_BIT_IN-1);

y_hat = lutobj.at(tQ,N_BIT_IN);
y_grt = func(tQ);

subplot(211)
plot(t,y,'p-',tQ,y_hat,'o-',tQ,y_grt,'s-','markersize',10)
lutobj.memsizeKB();
subplot(212)
plot(abs(y_grt-y_hat))