close all
rawDataDir = 'C:\Users\ychechik\Desktop\POC4_1D_new';
ivsFn = fullfile(rawDataDir,'record_03.ivs');

debugFlag = 1;
readRawFlag = 0;
%% read data to .ivs
if(readRawFlag)
    POCanalyzer(rawDataDir,0)
end
% %% get fw for later
% fw = Firmware('..\..\+Pipe\tables');
% csvPath = fileparts(ivsFn);
% fw.setRegs(fullfile(csvPath,'config.csv'));
% fw.setRegs(fullfile(csvPath,'calib.csv'));
% % [regs,luts] = fw.get();
% memoryLayout = Pipe.setDefaultMemoryLayout();
% lgr = Logger();

%% read ivs
piStruct = io.readIVS(ivsFn);

if(debugFlag)
    nSparse = 1:50:size(piStruct.xy,2);
    nStart = 1:100000;
    figure(332999);clf;plot(piStruct.xy(2,nStart),'-*');
    title('fast axis over time')
end


%% find scan direction change to manipulate the single line y to xy map
scanDirBitNum = 3;
scanDir = bitget(piStruct.flags, scanDirBitNum, 'uint8');

scanDirChange = double(scanDir(1:end-1))-double(scanDir(2:end)) ~= 0;
scanDirChange(end+1) = 0;

%% right now the max/min isn't found right... lets find it in a good way
ExtremumInd = find(scanDirChange);
maxY = max(piStruct.xy(2,:));
minY = min(piStruct.xy(2,:));

isFirstMax = 0;
if(abs(piStruct.xy(2,ExtremumInd(1))-maxY)<abs(piStruct.xy(2,ExtremumInd(1))-minY))
    isFirstMax = 1;
end

delta = 200;
extremums = zeros(size(scanDirChange));
for i=1:sum(scanDirChange)
    %open a sleeve around the etremum and find it precise
    
    ind = max(ExtremumInd(i)-delta,1):min(ExtremumInd(i)+delta,length(scanDirChange));
    if(mod(i+isFirstMax,2)==0) %max
        extremums(maxind(piStruct.xy(2,ind))-1+ind(1))=1;
    else
    extremums(minind(piStruct.xy(2,ind))-1+ind(1))=1;
    end
end

%%


if(debugFlag)
    figure(11012);clf
    n = 1:1000000;
    y = double(piStruct.xy(2,:));
    plot(y(n),'-*');
    
%     y(scanDirChange == 0) = nan;
    y(extremums == 0) = nan;
    
    hold on;plot(y(n),'or','MarkerSize',30);
end

xNew = cumsum(extremums);
xNewQ = int16(min((xNew/max(xNew)*2 -1)*2^11,2^11-1));

if(debugFlag)
    figure(3243);clf;plot(xNewQ(1,1:100000),piStruct.xy(2,1:100000),'-*')
end

piStructNew = piStruct;
piStructNew.xy(1,:) = xNewQ;


%% roll the xy vs slow
y = double(piStruct.xy(2,:));
sz = [ max(xNew)+1 1024];%2048];%(y-(min(y)))/(max(y)-min(y))*2048 ]; %y is in helf HD size
f = figure(34632);clf;maximize(f)

% nregs = [];
% nregs.DIGG.sphericalEn = true;
% nregs.FRMW.xres = uint16(max(xNew));
% fw.setRegs(nregs,fullfile(csvPath,'config.csv'))
% [regs,luts] = fw.get();
for j =-55%-95:10:0%+1560%700:20:800% -95+1560 %2943
     piStructNew.slow = circshift(piStruct.slow,j);
    
    %PIPE BEGIN
%     [pipeOutData,pipeOutData.memoryLayoutOut] = Pipe.hwpipe(piStructNew, regs, luts,memoryLayout,lgr,[]);
    pipeOutData.iImgRAW = aux.ivs2irRaw(piStructNew,0,sz);
    % view results
    tabplot(['phase = ' num2str(j)],f);
    imagesc(pipeOutData.iImgRAW);colormap gray
    drawnow;
end
%% up & down
minxInd = find(piStructNew.xy(1,:) == min(piStructNew.xy(1,:)));
isFirstRowDown = (piStructNew.xy(2,1)-piStructNew.xy(2,max(minxInd)))>0;

up = pipeOutData.iImgRAW(:,1+isFirstRowDown:2:end);
down = pipeOutData.iImgRAW(:,2-isFirstRowDown:2:end);

figure(231123);clf
subplot(121);imagesc(up);colormap gray;title('up');
subplot(122);imagesc(down);colormap gray;title('down');

%%
figure(2341);clf;
a(1) = subplot(121);
errorbar(mean(up,2),std(up,0,2));hold on;plot(mean(up,2),'r');
title('up')
a(2) = subplot(122);
errorbar(mean(down,2),std(down,0,2));hold on;plot(mean(down,2),'r')
title('down')


linkaxes(a)

%%
figure
errorbar(mean(pipeOutData.iImgRAW,2),std(pipeOutData.iImgRAW,0,2));hold on;plot(mean(pipeOutData.iImgRAW,2),'r');


