function err = losToolSlowAx(varargin)
p = inputHandler(varargin{:});
fprintf('losToolSlowAx running on folder:\n\n%s\n\n', p.basedir)
fprintf('%d ivs files found\n reading ivses...\n',length(p.ivsFilenames))
ivsArr = cellfun(@(ivsFilename) io.readIVS(ivsFilename),p.ivsFilenames,'UniformOutput',0);
calibIndx = max(1,min(p.calibImIndx,length(ivsArr)));
fprintf('search for slow channel delay by ivs index %d\n%s\n\n',calibIndx,p.ivsFilenames{calibIndx})
[~, slowChDelay] = Calibration.aux.mSyncerPipe(ivsArr{calibIndx},[],p.calibVerbose);
fprintf('slow channel delay = %d\n', slowChDelay)
fprintf('generet IR scan images...')
irArr = cellfun(@(ivs) Utils.raw2img(ivs,slowChDelay,[720,1280]),ivsArr,'UniformOutput',0);

[imagePoints,bsz] = cellfun(@(ir) detectCheckerboardPoints(ir),irArr,'UniformOutput',0);

if isempty(bsz{1})
    error('cant find checker board point!!!')
end
if any(cellfun( @(bszi) any(bszi ~= bsz{1}),bsz(2:end)))
    error('checker board point numbers not equal in all images!!!')
end
distfunc = @(v) max(abs([vec(real(v(:)-v(:).')), vec(imag(v(:)-v(:).'))]));
ip=cell2mat(cellfun(@(x) (x(:,1)+1j*x(:,2)).',imagePoints,'uni',0));
err = max(reshape(cell2mat(arrayfun(@(i) distfunc(ip(:,i)),1:size(ip,2),'UniformOutput',0)),2,size(ip,2)),[],2);
fprintf('Scan Error X:\n\n%d\n\nScan Error Y:\n\n%d\n\n', err(1),err(2))
end


function p = inputHandler(basedir,varargin)
%defs
defs.verbose = 1;
defs.calibVerbose = 0;
defs.calibImIndx = 1;
defs.newFig = false;

defs.calibfn = fullfile(basedir,filesep,'calib.csv');
defs.configfn =fullfile(basedir,filesep,'config.csv');

% varargin parse
p = inputParser;

isfile = @(x) exist(x,'file');
isflag = @(x) or(isnumeric(x),islogical(x));

% addOptional(p,'verbose',defs.verbose,isflag);
addOptional(p,'calibVerbose',defs.calibVerbose,isflag);
addOptional(p,'calibFile',defs.calibfn,isfile);
addOptional(p,'configFile',defs.configfn,isfile);
addOptional(p,'calibImIndx',defs.calibImIndx,@isnumeric);
addOptional(p,'newFig',defs.newFig,isflag);

parse(p,varargin{:});

p = p.Results;



p.basedir = basedir;
p.basedir(p.basedir == '"') = [];
p.ivsFilenames = dirRecursive(p.basedir,'*.ivs');
end