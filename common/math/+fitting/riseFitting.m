
function [OUT,xi,yi, Rise,sigm_param,pout,fiterr] = riseFitting(yiIn,initial_params)

xi = find(~isnan(yiIn));
yi = yiIn(xi);


fsigm = @(param,xval) param(1)+(param(2)-param(1))./(1+10.^((param(3)-xval)*param(4)));
inv_fsigm = @(param,yval) ( (param(3)*param(4)) - (log10((-param(2)+yval)/(param(1)-yval )  ))/(log10(10))   )/param(4);
precent_sigm = @(param,percent) param(1) + percent*(param(2)-param(1));

try
    NS = conv(yi,(ones(1,5))/5,'same');
    NS(1:3) = nan;NS(end-3:end) = nan;
    [~,m] = max(abs(diff(NS))); m= m+5;  
catch
    m=length(yi)/2;
end

if ~exist('initial_params','var')
    initial_params = [];
end
if mean(diff(yi))>0 && isempty(initial_params)
    initial_params = [fitting.prctile(yi,5) fitting.prctile(yi,95) m 1];
else
    initial_params = [fitting.prctile(yi,95) fitting.prctile(yi,5) m 1];
end

% nan initialization
Rise = nan;OUT = nan(size(xi));
mse = nan;sigm_param = nan(4,1);
try
    [sigm_param,r]= fitting.nlinfit(xi,yi,fsigm,initial_params);
    fiterr = norm(r);
    OUT = fsigm(sigm_param,xi);
    ps09 = precent_sigm(sigm_param,0.9); ips09=inv_fsigm(sigm_param,ps09);
    ps01 = precent_sigm(sigm_param,0.1); ips01=inv_fsigm(sigm_param,ps01);
    
    Rise = abs(ips01-ips09);
    pout = [ps09,ips09,ps01,ips01];
catch
end

end