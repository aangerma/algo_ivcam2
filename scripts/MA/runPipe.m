function pipeOutData = runPipe(ivsFn)
% mcc -m runPipe.m -d '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\runPipe\' -a ..\..\+Pipe\tables\* 

pipeOutData = Pipe.autopipe(ivsFn);
end