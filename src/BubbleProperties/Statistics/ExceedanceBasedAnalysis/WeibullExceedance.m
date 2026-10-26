function S = WeibullExceedance(p,v)
% p(1) median
% p(2) standard deviation

mu = 10.^p(1);
kappa =  1./log(10)./p(2);

% exceedance
lambda = 1./mu;
S = exp(-(lambda.*v).^kappa);        % n_b(v'>v)/V_ref [m^-3]

end
