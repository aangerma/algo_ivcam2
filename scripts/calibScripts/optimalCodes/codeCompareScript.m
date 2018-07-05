% For each script, write and record its images

clear
%% Prepare configurations. Show all pixels as confidence depeneds on the code. Collect all data and save it.
hw = HWinterface;
hw.cmd('mwd a00e1894 a00e1898 00000000 // JFILinvConfThr');
hw.shadowUpdate();
p = @(s) [fullfile(pwd,'sc',s),'.txt'];
dp = @(s) [fullfile('X:\Data\IvCam2\codesCompare\unit33',s),'.mat'];
codes = {'code52_dec4';'code64_dec8';'code64_dec4'};

scnames = {p(codes{1});p(codes{2}); p(codes{3})};
dpath = {dp(codes{1});dp(codes{2});dp(codes{3})};

for c = 1:numel(codes)
    fprintf(codes{c});fprintf('\n');
    % Set the current code
    setCode(hw,scnames{c});
    % Collect data from different distances.
    collectData(hw,dpath{c});
end

% for c = 1:numel(dpath)
%     mat = load(dpath{c});
%     frame = mat.raw;
%     for i = 1:numel(frame)
%         imname = strcat(codes{c},sprintf('_ir_im_%d.png',i));
%         imwrite(frame(i).i/255,imname);
%     end
% end


%% Identify the board in all the images.      
load('X:\Data\IvCam2\codesCompare\unit33\IRimages\tragetROI.mat');
roi{1} = targetROI(1:22);
roi{2} = targetROI(22+1:22+30);
roi{3} = targetROI(53:end);
stdTh = 30;
% Get metric per distance
for ci = 1:numel(codes)
    % Single code
    mat = load(dpath{ci});
    frame = mat.raw;
    frame_std = mat.rawstd;

    % histStdByDist = zeros(numel(stdEdges)-1,numel(frame_std));
    avgDist = zeros(1,numel(frame_std));
    avgStd = zeros(1,numel(frame_std));
    underStdTh = zeros(1,numel(frame_std));
    avgStd90prc = zeros(1,numel(frame_std));
    largeStdWithCloseMean = zeros(1,numel(frame_std));
    for i = 1:numel(frame_std)
        r = roi{ci}(i).objectBoundingBoxes;
        std_ = frame_std(i).z(r(2):r(2)+r(4)-1,r(1):r(1)+r(3)-1)/8;
        depth_ = frame(i).z(r(2):r(2)+r(4)-1,r(1):r(1)+r(3)-1)/8;
        avgDist(i) = mean(depth_(std_<stdTh));
        avgStd(i) = mean(std_(std_<stdTh));
        avgStd90prc(i) = mean(std_(std_<prctile(std_(:),90)));
        underStdTh(i) = sum(std_(:)<stdTh)./(r(4)*r(3));
        largeStdWithCloseMean(i) = sum(vec((std_>=stdTh).*(abs(depth_-avgDist(i))<0.01*avgDist(i))))./(r(4)*r(3));
    end

    results{ci,1} = avgDist;
    results{ci,2} = avgStd;
    results{ci,3} = avgStd90prc;
    results{ci,4} = underStdTh;
    results{ci,5} = largeStdWithCloseMean;
end
save 'X:\Data\IvCam2\codesCompare\unit33\maxRangeResults.mat' results
%% Show the results nicely
metricn = {'avgStdUnderTh'; 'avgStd90prc'; 'underStdTh'; 'largeStdWithCloseMean'};
legs = {'52_4';'64_8';'64_4'};
% avg std under 30mm per code
ci_vec = [1,3];
subplot(3,1,1);
for ci = ci_vec
    [dist,ord] = sort(results{ci,1}/1000);
    stdUnderTh = results{ci,2};
    plot(dist,stdUnderTh(ord),'-o', 'LineWidth', 2);
    hold on
end
grid on
title('avg std under 30mm per code');
ylabel('std(mm)');
xlabel('dist(m)');
legend(legs(ci_vec));
% avg std under 90 percentile per code
subplot(3,1,2);
for ci = ci_vec
    [dist,ord] = sort(results{ci,1}/1000);
    stdUnder90 = results{ci,3};
    plot(dist,stdUnder90(ord),'-o', 'LineWidth', 2);
    hold on
end
grid on
title('avg std under 90 percentile per code');
ylabel('std(mm)');
xlabel('dist(m)');
legend(legs(ci_vec));

% percent of pixels under std th per code
subplot(3,1,3);
for ci = ci_vec
    [dist,ord] = sort(results{ci,1}/1000);
    underStdThPerc = results{ci,4};
    plot(dist,underStdThPerc(ord)*100,'-o', 'LineWidth', 2);
    hold on
end
grid on
title('percent of pixels under std th per code');
ylabel('%');
xlabel('dist(m)');
legend(legs(ci_vec));
% large std with close mean
% tabplot;
% for ci = 1:3
%     [dist,ord] = sort(results{ci,1}/1000);
%     largeStdWithCloseMean = results{ci,5};
%     plot(dist,largeStdWithCloseMean(ord)*100);
%     hold on
% end
% title('largeStdWithCloseMean');
% ylabel('%');
% xlabel('dist(m)');
% legend(legs);


