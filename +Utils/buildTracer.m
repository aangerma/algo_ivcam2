function buildTracer(txtMatIn,fileName,traceOutDir)

if isa(txtMatIn, 'int8')
	nl = zeros(1, size(txtMatIn,2), 'int8');
	nl(:) = 10; % newline (\n)
	fid = fopen(fullfile(traceOutDir,['tracer_' fileName '.txt']),'w');
	fwrite(fid, [txtMatIn; nl]);
	fclose(fid);
elseif isa(txtMatIn, 'char')
	txtMat = [txtMatIn char(repmat(10,size(txtMatIn,1),1))];
	outTxt = vec(txtMat');
	fid = fopen(fullfile(traceOutDir,['tracer_' fileName '.txt']),'w');
	writeind = [0:1e8:length(outTxt) length(outTxt)];
	for i=1:length(writeind)-1
		fprintf(fid,outTxt(writeind(i)+1:writeind(i+1)));
	end
	fclose(fid);
else
	error 'Only char and int8 are support for text output';
end

end