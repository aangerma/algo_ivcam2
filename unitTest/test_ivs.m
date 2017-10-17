rng(1)
N_PACKETS = 4e3;
N = 64*N_PACKETS;
ivs.fast = rand(1,N)>.5;
ivs.slow = uint16(rand(1,N/64)*(2^16-1));
ivs.xy     =  int16(rand(2,N/64)*(2^12-1));
ivs.flags  = uint16(rand(1,N/64)*(2^8-1));
fn = [tempname '.ivs'];
t1=tic;
ok=io.writeIVS(fn,ivs);
t1=toc(t1);

t2=tic;
ivs2 = io.readIVS(fn);
t2=toc(t2);

assert(sum(abs(double(ivs2.fast)-double(ivs.fast)))==0);
assert(sum(abs(double(ivs2.slow(:))-double(ivs.slow(:))))==0);
assert(sum(abs(double(ivs2.xy(:))-double(ivs.xy(:))))==0);
assert(sum(abs(double(ivs2.flags(:))-double(ivs.flags(:))))==0);

fprintf('Read: %.1fsec/1Mpackets, Write: %.1fsec/1Mpackets\n',t1/N_PACKETS*1e6,t2/N_PACKETS*1e6);

