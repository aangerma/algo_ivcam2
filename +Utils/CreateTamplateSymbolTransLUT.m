function [result] = CreateTamplateSymbolTransLUT(fn)
    if ~exist('fn','var')
        fn = 'C:\algo\algo_ivcam2\+Calibration\initConfigCalib\FRMWtmpTrans.bin32';
    end
    result = true;
    tamplate_symbol_trans_LUT_16 = zeros(64,8,16);
    tamplate_symbol_trans_LUT_8  = zeros(64,8,8);
    tamplate_symbol_trans_LUT_4  = zeros(64,8,4);
    nTemplates = 64;
    %% rx2tx = 16
        tamplate_symbol_trans_LUT_16(1,:,:) = [[0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0];  % 0 0 0
                                              [0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0];  % 0 0 1 
                                              [7 7 7 7 7 7 7 7  7 7 7 7 7 7 7 7];  % 0 1 0 
                                              [7 7 7 7 7 7 7 7  7 7 7 7 7 7 7 7];  % 0 1 1 
                                              [0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0];  % 1 0 0 
                                              [0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0];  % 1 0 1 
                                              [7 7 7 7 7 7 7 7  7 7 7 7 7 7 7 7];  % 1 1 0 
                                              [7 7 7 7 7 7 7 7  7 7 7 7 7 7 7 7]]; % 1 1 1 

        for (i=2:nTemplates) % place older for manipulate tamplate index > 1
            tamplate_symbol_trans_LUT_16(i,:,:) = tamplate_symbol_trans_LUT_16(1,:,:); %+i*10;
        end
       
    %% rx2tx = 8 
        %tamplate_entery_LUT_8 = [
                                         %  0 0 0           0 0 1               0 1 0               0 1 1                 1 0 0           1 0 1               1 1 0               1 1 1     Index
        tamplate_symbol_trans_LUT_8(1,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 1
        tamplate_symbol_trans_LUT_8(2,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 2
        tamplate_symbol_trans_LUT_8(3,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 3
        tamplate_symbol_trans_LUT_8(4,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 4
        tamplate_symbol_trans_LUT_8(5,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 5
        tamplate_symbol_trans_LUT_8(6,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 6
        tamplate_symbol_trans_LUT_8(7,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 7
        tamplate_symbol_trans_LUT_8(8,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 8

        tamplate_symbol_trans_LUT_8(9,:,:) =  [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 9
        tamplate_symbol_trans_LUT_8(10,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 10
        tamplate_symbol_trans_LUT_8(11,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 11
        tamplate_symbol_trans_LUT_8(12,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 12
        tamplate_symbol_trans_LUT_8(13,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 13
        tamplate_symbol_trans_LUT_8(14,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 14
        tamplate_symbol_trans_LUT_8(15,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 15
        tamplate_symbol_trans_LUT_8(16,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 16

        tamplate_symbol_trans_LUT_8(17,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 17
        tamplate_symbol_trans_LUT_8(18,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 18
        tamplate_symbol_trans_LUT_8(19,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 19
        tamplate_symbol_trans_LUT_8(20,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 20
        tamplate_symbol_trans_LUT_8(21,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 21
        tamplate_symbol_trans_LUT_8(22,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 22
        tamplate_symbol_trans_LUT_8(23,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 23
        tamplate_symbol_trans_LUT_8(24,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 24

        tamplate_symbol_trans_LUT_8(25,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 25
        tamplate_symbol_trans_LUT_8(26,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 26
        tamplate_symbol_trans_LUT_8(27,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 27
        tamplate_symbol_trans_LUT_8(28,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 28
        tamplate_symbol_trans_LUT_8(29,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 29
        tamplate_symbol_trans_LUT_8(30,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 30
        tamplate_symbol_trans_LUT_8(31,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 31
        tamplate_symbol_trans_LUT_8(32,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 32

        tamplate_symbol_trans_LUT_8(33,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 33
        tamplate_symbol_trans_LUT_8(34,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 34
        tamplate_symbol_trans_LUT_8(35,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 35
        tamplate_symbol_trans_LUT_8(36,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 36
        tamplate_symbol_trans_LUT_8(37,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 37
        tamplate_symbol_trans_LUT_8(38,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 38
        tamplate_symbol_trans_LUT_8(39,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(40,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 40

        tamplate_symbol_trans_LUT_8(41,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 41
        tamplate_symbol_trans_LUT_8(42,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 42
        tamplate_symbol_trans_LUT_8(43,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 43
        tamplate_symbol_trans_LUT_8(44,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 44
        tamplate_symbol_trans_LUT_8(45,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 45
        tamplate_symbol_trans_LUT_8(46,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 46
        tamplate_symbol_trans_LUT_8(47,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 47
        tamplate_symbol_trans_LUT_8(48,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 48

        tamplate_symbol_trans_LUT_8(49,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 49
        tamplate_symbol_trans_LUT_8(50,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(51,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(52,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(53,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(54,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(55,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(56,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 56

        tamplate_symbol_trans_LUT_8(57,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 57
        tamplate_symbol_trans_LUT_8(58,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(59,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(60,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(61,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(62,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(63,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 
        tamplate_symbol_trans_LUT_8(64,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7];[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 0];[7 7 7 7 7 7 7 7];[7 7 7 7 7 7 7 7]]; % 64
        
    %% rx2tx = 4
        nTemplates = 64;
               tamplate_symbol_trans_LUT_4(1,:,:) = [[0 0 0 0];  % 0 0 0
                                            [0 0 0 0];  % 0 0 1 
                                            [7 7 7 7];  % 0 1 0 
                                            [7 7 7 7];  % 0 1 1 
                                            [0 0 0 0];  % 1 0 0 
                                            [0 0 0 0];  % 1 0 1 
                                            [7 7 7 7];  % 1 1 0 
                                            [7 7 7 7]]; % 1 1 1 
        for (i=2:nTemplates) % place older for manipulate tamplate index > 1
            tamplate_symbol_trans_LUT_4(i,:,:) = tamplate_symbol_trans_LUT_4(1,:,:);
        end
        b1 = permute(tamplate_symbol_trans_LUT_16,[3 2 1]);
        b2 = permute(tamplate_symbol_trans_LUT_8,[3 2 1]);
        b3 = permute(tamplate_symbol_trans_LUT_4,[3 2 1]);
        b  = bitand([b1(:);b2(:);b3(:)],7);
        b = reshape(b(:),8,[]);
        b = uint32(b(1,:) + bitshift(b(2,:),4) +  bitshift(b(3,:),8) + bitshift(b(4,:),12) + ...
            bitshift(b(5,:),16) + bitshift(b(6,:),20) +  bitshift(b(7,:),24) + bitshift(b(8,:),28));

        io.writeBin(fn,b);
end 

function [tamplate_symbol_trans_LUT] = getTamplateSymbolTransLUT_sample_not_used(rx2tx)
    
    tamplate_entery_LUT_8 = zeros(64,8,rx2tx);
    switch rx2tx
    case 8       %% symetric rasie/full time 4 sample 
        %tamplate_entery_LUT_8 = [
                                         %  0 0 0           0 0 1               0 1 0               0 1 1                 1 0 0           1 0 1               1 1 0               1 1 1     Index
        tamplate_entery_LUT_8(1,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 1
        tamplate_entery_LUT_8(2,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 2
        tamplate_entery_LUT_8(3,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 3
        tamplate_entery_LUT_8(4,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 4
        tamplate_entery_LUT_8(5,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 5
        tamplate_entery_LUT_8(6,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 6
        tamplate_entery_LUT_8(7,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 7
        tamplate_entery_LUT_8(8,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 8

        tamplate_entery_LUT_8(9,:,:) =  [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 9
        tamplate_entery_LUT_8(10,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 10
        tamplate_entery_LUT_8(11,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 11
        tamplate_entery_LUT_8(12,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 12
        tamplate_entery_LUT_8(13,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 13
        tamplate_entery_LUT_8(14,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 14
        tamplate_entery_LUT_8(15,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 15
        tamplate_entery_LUT_8(16,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 16

        tamplate_entery_LUT_8(17,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 17
        tamplate_entery_LUT_8(18,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 18
        tamplate_entery_LUT_8(19,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 19
        tamplate_entery_LUT_8(20,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 20
        tamplate_entery_LUT_8(21,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 21
        tamplate_entery_LUT_8(22,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 22
        tamplate_entery_LUT_8(23,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 23
        tamplate_entery_LUT_8(24,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 24

        tamplate_entery_LUT_8(25,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 25
        tamplate_entery_LUT_8(26,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 26
        tamplate_entery_LUT_8(27,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 27
        tamplate_entery_LUT_8(28,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 28
        tamplate_entery_LUT_8(29,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 29
        tamplate_entery_LUT_8(30,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 30
        tamplate_entery_LUT_8(31,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 31
        tamplate_entery_LUT_8(32,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 32

        tamplate_entery_LUT_8(33,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 33
        tamplate_entery_LUT_8(34,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 34
        tamplate_entery_LUT_8(35,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 35
        tamplate_entery_LUT_8(36,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 36
        tamplate_entery_LUT_8(37,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 37
        tamplate_entery_LUT_8(38,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 38
        tamplate_entery_LUT_8(39,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(40,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 40

        tamplate_entery_LUT_8(41,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 41
        tamplate_entery_LUT_8(42,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 42
        tamplate_entery_LUT_8(43,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 43
        tamplate_entery_LUT_8(44,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 44
        tamplate_entery_LUT_8(45,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 45
        tamplate_entery_LUT_8(46,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 46
        tamplate_entery_LUT_8(47,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 47
        tamplate_entery_LUT_8(48,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 48

        tamplate_entery_LUT_8(49,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 49
        tamplate_entery_LUT_8(50,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(51,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(52,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(53,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(54,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(55,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(56,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 56

        tamplate_entery_LUT_8(57,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 57
        tamplate_entery_LUT_8(58,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(59,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(60,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(61,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(62,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(63,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 
        tamplate_entery_LUT_8(64,:,:) = [[0 0 0 0 0 0 0 0];[0 0 0 0 0 0 0 3];[5 7 7 7 7 7 7 5];[5 7 7 7 7 7 7 7];[3 0 0 0 0 0 0 0];[3 0 0 0 0 0 0 3];[7 7 7 7 7 7 7 5];[7 7 7 7 7 7 7 7]]; % 64
        
    case 4
        nTemplates = 64;
        %% symetric rasie/full time 8 sample 
        tamplate_entery_LUT_8(1,:,:) = [[0 0 0 0];  % 0 0 0
                                        [0 0 1 3];  % 0 0 1 
                                        [5 7 6 4];  % 0 1 0 
                                        [5 7 7 7];  % 0 1 1 
                                        [2 0 0 0];  % 1 0 0 
                                        [2 0 1 3];  % 1 0 1 
                                        [7 7 6 4];  % 1 1 0 
                                        [7 7 7 7]]; % 1 1 1 
        for (i=2:nTemplates) % place older for manipulate tamplate index > 1
            tamplate_entery_LUT_8(i,:,:) = tamplate_entery_LUT_8(1,:,:);
        end

    case 16
        nTemplates = 64;
        %% symetric rasie/full time 10 sample 
        tamplate_entery_LUT_8(1,:,:) = [[0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0];  % 0 0 0
                                        [0 0 0 0 0 0 0 0  0 0 0 0 0 1 2 3];  % 0 0 1 
                                        [3 4 5 6 7 7 7 7  7 7 7 7 6 5 4 3];  % 0 1 0 
                                        [3 4 5 6 6 7 7 7  7 7 7 7 7 7 7 7];  % 0 1 1 
                                        [3 2 1 0 0 0 0 0  0 0 0 0 0 0 0 0];  % 1 0 0 
                                        [3 2 1 0 0 0 0 0  0 0 0 0 0 1 2 3];  % 1 0 1 
                                        [7 7 7 7 7 7 7 7  7 7 7 6 6 5 4 3];  % 1 1 0 
                                        [7 7 7 7 7 7 7 7  7 7 7 7 7 7 7 7]]; % 1 1 1 
        for (i=2:nTemplates) % place older for manipulate tamplate index > 1
            tamplate_entery_LUT_8(i,:,:) = tamplate_entery_LUT_8(1,:,:);
        end

                                 
        otherwise
           return
    end
    tamplate_symbol_trans_LUT = tamplate_entery_LUT_8;
end
