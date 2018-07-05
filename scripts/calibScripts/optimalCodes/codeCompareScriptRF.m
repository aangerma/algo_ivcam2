% For each script, write and record its images

clear
%% Prepare configurations. Show all pixels as confidence depeneds on the code. Collect all data and save it.
hw = HWinterface;
hw.cmd('mwd a00e1894 a00e1898 00000000 // JFILinvConfThr');
hw.shadowUpdate();
p = @(s) [fullfile(pwd,'sc',s),'.txt'];
dp = @(s) [fullfile('X:\Data\IvCam2\codesCompare\unit33',s),'.mat'];
codes = {'code52_dec4';'code64_dec8';'code64_dec4'};
codesMat = {'52_4_rf';'64_8_rf';'64_4_rf'};

scnames = {p(codes{1});p(codes{2}); p(codes{3})};
dpath = {dp(codesMat{1});dp(codesMat{2});dp(codesMat{3})};

for c = 1:numel(codes)
    fprintf(codes{c});fprintf('\n');
    % Set the current code
    setCode(hw,scnames{c});
    % Collect data from different distances.
    collectDataRF(hw,dpath{c});
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
% Get metric per distance
for ci = 1:numel(codes)
    % Single code
    mat = load(dpath{ci});
    z{ci} = mat.raw/8;
    zstd{ci} = mat.rawstd/8;
    
end
%% Show the results nicely
legs = {'52_4';'64_8';'64_4'};
% avg std under 30mm per code
ci_vec = [1,2,3];
for ci = ci_vec
    [dist,ord] = sort(z{ci}/1000);
    currstd = zstd{ci};currstd = currstd(ord);
    plot(dist(dist<=2.6),currstd(dist<=2.6),'-o', 'LineWidth', 2);
    hold on
end
grid on
title('rf std per code');
ylabel('std(mm)');
xlabel('dist(m)');
legend(legs(ci_vec));