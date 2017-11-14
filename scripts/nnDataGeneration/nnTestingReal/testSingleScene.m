addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\git\ivcam2.0'))
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\git\AlgoCommon\Common'))

% fw.setRegs(regs,p.configOutputFilename);
% fw.writeUpdated(p.configOutputFilename);
% calibFilename = fullfile(p.outputDir,filesep,'calib.csv');
% fid=fopen(calibFilename,'w');
% fclose(fid);


ivs = 'X:\Data\IvCam2\NN\capturedScenes\Sagy\record_04.ivs';
pout = Pipe.autopipe(ivs,'verbose',0,'viewResults',0,'saveresults',0);

% nnNorm = single(1/64000);1

% netInputDepth =  Utils.fp20('to',pout.nnfeatures.d(:,:,1))/nnNorm;
% netOutputDepth = pout.dNNOutput;
% netOutputExpected = dnnExact(Utils.fp20('to',pout.nnfeatures.d));
% 
% ivbin_viewer(netInputDepth,netOutputDepth)
% ivbin_viewer(netOutputDepth,netOutputExpected)


%% View BT results from Tensorflow
BTStages = pout.BTStages;
ivbin_viewer({BTStages.preBT1,BTStages.BT1,BTStages.BT2,pout.dNNOutput,BTStages.BT3,pout.zImg})
%% 
BTStages_tf_clipped = load('X:\Data\IvCam2\NN\capturedScenes\Sagy\BTStages_tf_clipped.mat');
BTStages_tf_comb = load('X:\Data\IvCam2\NN\capturedScenes\Sagy\BTStages_tf_comb.mat');
ivbin_viewer({BTStages_tf_comb.preBT1,BTStages_tf_comb.BT1,BTStages_tf_comb.BT2,BTStages_tf_comb.BT2_nn,BTStages_tf_comb.BT3,BTStages_tf_comb.BT3_initial})
