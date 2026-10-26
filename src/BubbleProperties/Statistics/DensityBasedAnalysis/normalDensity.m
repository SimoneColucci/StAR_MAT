function n_lin = normalDensity(p,x)

alpha = p(1);   % cumulative number density
nu = p(2);      % mean
sigma = p(3);   % standard deviation
    
    % exceedance density
    %N = alpha.*exp(-(lambda.*v).^kappa);;        % n_b(v'>v)/V_ref [m^-3]
    
    % cumulative number density
    N_tot = alpha;                     % n_tot/V_ref [m^-3]
    
    % exceedance
    %S = N./N_tot;                       % n_b(>v)/n_tot;
    
    % distribution density (probability density)
    %mu = 1./lambda;
    %ftilde = (kappa./mu).*(v./mu).^(kappa-1).*exp(-(v./mu).^kappa);              % n_b(v)/dv/n_tot [m^-3]
    
    % linear distribution density Base 10 log scale (probability density)
    %nu = log10(mu);
    %sigma = 1./log(10)./kappa;
    %x = log10(v);
    ftilde_lin = 1./(sigma*sqrt(2*pi)).*exp(-((x-nu).^2)./(2*sigma.^2));
    
    % number density
    %n = N_tot.*ftilde;              % n_b(v)/dv/V_ref [m^-4]
    
    % Linear number density
    n_lin = N_tot.*ftilde_lin;      % n_b(v)/dv/V_ref [m^-4]
    
end
