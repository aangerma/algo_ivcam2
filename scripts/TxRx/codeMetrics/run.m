load('X:\Users\tomer\codes_data\450\32_2.mat'); 
codesStruct='X:\Users\tomer\FG\codes.mat' ;
load(codesStruct); 
outputFolder='X:\Users\hila\L520\TxRx\AnalyzeCodes\dis450\32_2'; 
codeName='32_2'; 

codeInd=find(strcmp({codes.name},codeName)); 
AnalyzeAverageCode(codes(codeInd),fast,outputFolder,saveExp); 