function S = normalExceedance(p,v)
% p(1) median
% p(2) standard deviation

mu = 10.^p(1);
kappa =  1./log(10)./p(2);

% exceedance
S = 0.5*erfc(kappa.*log(v./mu)/sqrt(2));        % n_b(v'>v)/V_ref [m^-3]

end
