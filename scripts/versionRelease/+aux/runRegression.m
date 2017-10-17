function logfn= runRegression(dbUpdate)
if(~exist('dbUpdate','var'))
    dbUpdate=false;
end
logfn='';
%% gen dirs for .html
RegressionDir = '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\Regression';
if(dbUpdate)
    RegOutput = [RegressionDir filesep 'regressionOut' filesep datestr(now,'yyyymmdd') filesep];
    if(~exist(RegOutput,'dir'))
        mkdir(RegOutput);
    end
    images_dir = ['image_dir' filesep];
    if(~exist( [RegOutput images_dir],'dir'))
        mkdir([RegOutput images_dir]);
    end
    logfn = [RegOutput 'log.html'];
    fid = fopen(logfn,'w');
    fprintf(fid,'<!DOCTYPE html> <html> <head> <style> table {     font-family: arial, sans-serif;     border-collapse: collapse;     width: 100%%; }  td, th {     border: 1px solid #dddddd;     text-align: left;     padding: 8px; }   </style> </head> <body>  <table>');
    fprintf(fid,'  <tr>     <th>Folder</th> <th>General</th>     <th>Depth (src ,dst, norm diff)</th>     <th>Confidence</th> 	<th>IR</th>   </tr>');
    
end




%% run on all reg files
fns = dirRecursive(RegressionDir,'*.ivs');

for k=1:length(fns)
    fn=fns{k};
    [path,name]  = fileparts(fn);
    fprintf('Running regression on %s ...',name);
    
    %run pipe
    Pipe.autopipe(fn,'saveResults',dbUpdate,'outputdir',[path filesep name '_' datestr(now,'yyyymmdd') filesep],'viewResults',false,'verbose',false,'rewrite',false);
    fprintf('done\n');
    if(~dbUpdate)
        continue;
    end
    %% compare results
    
    %compared file in reg
    [srcData,dstData,srcDir,dstDir]=getData(path,name);
    
    [~,srcDir ]=fileparts(srcDir);
    [~,dstDir ]=fileparts(dstDir);
    
    imgDiff = cellfun(@(x,y) (double(x)-double(y)),dstData,srcData,'uni',false);
    
    
    if(dbUpdate)
        fprintf(fid,'  <tr>     <td>%s</br>src:%s</br>dst:%s</td> <td>delta valid: %+d</br>delta conf:%+d</td>',name,srcDir,dstDir,round(100*(nnz(dstData{1})-nnz(srcData{1}))/nnz(srcData{1})),round(100*mean(imgDiff{2}(:))/mean(srcData{2}(:))));
        normVals = [100 15 255];
        style = {'ir','c','depth'};
        for i=1:3
            imgFn = cell(3,1);
            for j=1:3
                if(j==1)
                    imgFn{1} = sprintf('%s%s_delta_%s.png',images_dir,name,style{i});
                    imgBool = abs(imresize(imgDiff{i},.25));
                    imgBool = min(1,imgBool/normVals(i));
                    imgBool = gray2colormap(imgBool,parula(256));
                else
                    if(j==2)
                        imgFn{j} = sprintf('%s%s_src_%s.png',images_dir,name,style{i});
                        imgBool = abs(imresize(srcData{i},.25));
                    else %j==3
                        imgFn{j} = sprintf('%s%s_dst_%s.png',images_dir,name,style{i});
                        imgBool = abs(imresize(dstData{i},.25));
                    end
                    
                    if(max(imgBool(:))-min(imgBool(:))>0)
                        imgBoolnorm = (imgBool-min(imgBool(:)))/(max(imgBool(:))-min(imgBool(:)));
                    else
                        imgBoolnorm = zeros(size(imgBool));
                    end
                    imgBool = gray2colormap(imgBoolnorm,parula(256));
                end
                imwrite(imgBool,[RegOutput imgFn{j}]);
            end
            
            imgStat = sprintf('</br>max diff:%f</br>rmse:%f</br>',max(imgDiff{i}(:)),sqrt(mean(imgDiff{i}(:).^2)));
            fprintf(fid,'   <td><img src="%s" style="float:left;" alt=""/> <img src="%s" style="float:left;" alt=""/> <img src="%s" style="float:left;" alt=""/>%s</td>',imgFn{2},imgFn{3},imgFn{1},imgStat);
        end
        fprintf(fid,'   </tr>\r\n');
    end
    
    
    
    
    
end


if(dbUpdate)
    fprintf(fid,'</table></body></html>');
    fclose(fid);
end
fprintf('<a href="%s">open log file</a>\n',logfn);
end

function [srcData,dstData,srcDir,dstDir]=getData(path,name)
dd = dir([path filesep name '_*']);

dd =dd([dd.isdir]);
[~,ordr] = sort([dd.datenum]);
dd = {dd(ordr).name};
dstDir = [path filesep dd{end}];
if(length(dd)==1)
    srcDir = dstDir;
else
    srcDir = [path filesep dd{end-1}];
end
srcData = getDataFromFldr(srcDir);
dstData = getDataFromFldr(dstDir);
end

function data = getDataFromFldr(fldr)
data{1} = dataORnan(getFirst(fldr,'binz'));
%patch, zbin is *always 960x1280
if(any(size(data{1})~=[960 1280]))
     pdTL = floor(([960 1280]-size(data{1}))/2);
    data{1} = pad_array(data{1},pdTL,0,'pre');
    data{1} = pad_array(data{1},[960 1280]-size(data{1}),0,'post');
end
data{2} = dataORnan(getFirst(fldr,'binc'));
data{3} = dataORnan(getFirst(fldr,'bini'));

end

function fn = getFirst(fldr,ext)
fn = dirFiles(fldr,['*.' ext]);
if(isempty(fn))
    fn = 'junk';
else
    fn = fn{1};
end
end

function data = dataORnan(fn)
if(exist(fn,'file'))
    data = io.readBin(fn);

else
    %big 'x'
    data = zeros(480,640);
    data( sub2ind([480,480],1:480,1:480)) = 1;
    data( sub2ind([480,480],1:480,480:-1:1)) = 1;
end
end
