function S = exponentialExceedance(p,v)
% p(1) median
 
mu = 10.^p(1); 

% exceedance 
lambda = 1./mu;
S = exp(-lambda.*v);        % n_b(v'>v)/V_ref [m^-3]

end
