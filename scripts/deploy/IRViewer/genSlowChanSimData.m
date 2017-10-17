function slowChanSimParams = genSlowChanSimData()

csv_filter_files = {'\\invcam322\Ohad\data\lidar\simulatorParams\slowChannel\aafilter.csv'};

%the data of the filters is in logx &logy
f = linspace(0,10,501);
freqLogAxis = (10.^f)';


for i=1:length(csv_filter_files)
    
    m = csv2mat(csv_filter_files{i});
    [~,name] = fileparts(csv_filter_files{i});
    
    data = str2double(m(2:end,:));
    data_f = data(:,1);data=data(:,2:end);
    data_name = m(1,2:end);
    data=10.^(data/20);
    
    data = interp1(data_f,data,freqLogAxis,'linear','extrap');
    
    % figure(363);loglog(f,aaData(:,i));hold on;drawnow;
    
    
    slowChanSimParams.filters_freq = freqLogAxis;
    for j=1:size(data,2)
        slowChanSimParams.(name).(['type_' data_name{j}]) = data(:,j);
%         slowChanSimParams.([name 'Module'])(j).v = ;
    end
end


%% abs

m = csv2mat('\\invcam322\Ohad\data\lidar\simulatorParams\slowChannel\abs.csv');


input_amp = str2double(m(5:end,1));
freqs = unique(m(2,2:end));

for i =1:length(freqs)
    i_cols = strcmp(m(2,:),freqs{i});
    data = str2double(m(5:end,i_cols));
    curve_names = m(1,i_cols);
    
    
    slowChanSimParams.abs.input_amp = input_amp;
    for j=1:size(data,2)
        slowChanSimParams.abs.(['f_' freqs{i}]).([strrep(curve_names{j},' ','_')]) = data(:,j);
    end
end

struct2xmlWrapper(slowChanSimParams,'slowChanSimParams.xml');

end



function c = csv2mat(fn_in)
c=cellfun(@(x) str2cell(x,',')',str2cell(fileread(fn_in),13),'uni',false);
lc = cellfun(@(x) length(x),c);
c(lc~=median(lc))=[];
c=[c{:}]';
end