function varargout=xml2structWrapper(varargin)
xml_fn = varargin{1};
if(nargin>1)
    attrib=varargin(2:end);
else
    attrib={};
end

p = xml2struct(xml_fn);
f = fieldnames(p);
if(length(f)==1)
    p=p.(f{1});
else
    error('Bad struct format');
end
varargout = cell(length(attrib)+1,1);
varargout{1}=striptTextField(p);
for i=1:length(attrib)
    varargout{i+1}=striptAttribField(p,attrib{i});
end
end

function stout = striptTextField(stin)
stout=[];
if(isfield(stin,'Text'))
    if(~isempty(stin.Text) && stin.Text(1)=='@')
        stout = str2func(stin.Text);
    else
    stout = str2num(stin.Text);%#ok
    if(isempty(stout) && ~strcmp(stin.Text,'[]'))
        stout = stin.Text;
    end
    end
    return
end
f = fieldnames(stin);

for i=1:length(f)
    if(strcmpi(f{i},'comment'))
        continue;
    end
    stout.(f{i}) = striptTextField(stin.(f{i}));
end
end

function stout = striptAttribField(stin,attrib)
stout=[];
f = fieldnames(stin);
if(isfield(stin,'Attributes'))
    if(isfield(stin.Attributes,attrib))
        stout = stin.Attributes.(attrib);
        return;
    else
        return;
    end
end
if(isfield(stin,'Text'))
    return;
end
for i=1:length(f)
    if(strcmpi(f{i},'comment'))
        continue;
    end
    stout.(f{i}) = striptAttribField(stin.(f{i}),attrib);
end
end