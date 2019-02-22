function plotTemperature(frames,coolingStage)
Temp = [];
Time = [];
lastTime = 0;
tmpNames = fieldnames(frames{1}(1).temp );


for i = 1:numel(frames)
    iterFrames = frames{i};
    currtmp = [iterFrames.temp];
    currtmp = [[currtmp.ldd];[currtmp.mc];[currtmp.ma];[currtmp.tSense];[currtmp.vSense]]';
    currtime = [iterFrames.time]';
    
    if isempty(coolingStage(i).data)
        Temp = [Temp;currtmp];
        Time = [Time;lastTime+currtime];
        lastTime = max(Time);
    else
        coolingTmpVec = coolingStage(i).data(:,2:end);
        Temp = [Temp;currtmp;coolingTmpVec];
        Time = [Time;lastTime+currtime;lastTime+coolingStage(i).data(:,1)];
        lastTime = max(Time);
    end
    
    
    
    
    

end

for i = 1:numel(tmpNames)
    subplot(numel(tmpNames),1,i);
    plot(Time/3600,Temp(:,i),'DisplayName',tmpNames{i});
    xlabel('hours')
    legend(tmpNames{i})
end