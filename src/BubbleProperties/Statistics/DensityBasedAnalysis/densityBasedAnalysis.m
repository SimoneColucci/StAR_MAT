function [X2,Alpha,Mu,Sigma] = densityBasedAnalysis(v,sampleNew,method,RD,Idx,num,Mtype)

%% Data
% v is cell array. 
% Each cell contains particle sizes measurements from a sample
% The code combines these measurements and generates a combined histogram
% The combined histogram is given by arranging individual histograms from left
% (smaller size) to right (larger size)
% When single histograms overlap, the overlapping region of the left histogram is removed

% find minimum size for each measurement
Nm = numel(v);
minima = zeros(1,Nm);
log10v = cell(1,Nm);
for j = 1:Nm
    v_nozero = v{j}(v{j} ~= 0);
    log10v{j} = log10(v_nozero)';
    minima(j) = min(log10v{j});
end

% sort measurements from left to right
[~,Idx_sorted] = sort(minima);
log10v = log10v(Idx_sorted);

% Define bins
bin_edges = linspace(min([log10v{:}]),max([log10v{:}]),18);%16
bin_centers = bin_edges(1:end-1) + abs(diff(bin_edges))/2;

% calculate left and right edge limits of individual histograms
Il = zeros(1,Nm);
Ir = zeros(1,Nm);
for j= 1:Nm
    % Left edge
    % find minimum particle size
    min_log10vj = min(log10v{j});
    % find the index of the corresponding left bin
    Il(j) = find(bin_edges <= min_log10vj, 1, 'last'); %max( bin_edges(bin_edges <= min_log10vj) );
    % Right edge
    % find maximum particle size
    max_log10vj = max(log10v{j});
    % find the index of the corresponding right bin
    Ir(j) = find(bin_edges >= max_log10vj, 1, 'first'); % min( bin_edges(bin_edges >= max_log10vj) );
end

% remove overlapping region for individual histograms
Il_new = zeros(1,Nm);
Ir_new = zeros(1,Nm);
Il_new(1) = Il(1); 
for j = 2:Nm
    %if strcmp(method.remove_overlap{j-1},'left')
    %    Il_new(j) = min(Ir(j-1),Il(j));
    %elseif strcmp(method.remove_overlap{j-1},'right')
        Il_new(j) = max(Ir(j-1),Il(j));
    %end
end
Ir_new(1:Nm-1) = Il_new(2:Nm);
Ir_new(Nm) = Ir(end); 

% Calculate combined histogram
n_lin_array = cell(1,Nm);
sigma_array = cell(1,Nm);
Vtot = sampleNew.Depth.*sampleNew.Area.*sampleNew.px2m.*sampleNew.px2m;
Vtot = Vtot(Idx_sorted);
for j = 1:Nm
    n = histcounts( log10v{j},bin_edges( Il_new(j):Ir_new(j) ) );
    n_lin_array{j} = n./(Vtot(j)*diff(bin_edges( Il_new(j):Ir_new(j) )));
    sigma_array{j} = sqrt(max(0,n))./( Vtot(j)*diff(bin_edges( Il_new(j):Ir_new(j) ) ) );
end
n_lin = [n_lin_array{:}];
sigma = [sigma_array{:}];

% Normalize linear number density for computational efficiency
Vnorm = mean(Vtot);
n_lin_norm=n_lin*Vnorm;

%% Fitting    
Data.x = bin_centers;
Data.y = n_lin_norm;
Data.sigma = sigma*Vnorm;
I = find(n==0);
Data.sigma(I) = 1;

parameters.lowBound =  [min(n_lin_norm) (min([log10v{:}])) 1e-10];
parameters.highBound = [max(n_lin_norm)  (max([log10v{:}])) 1]; 

disp('#### Fitting based on distribution density ####')
% Exponential
DistributionName = 'Exponential';
[p_exponential,X2_exponential] = minsearch(parameters,Data,DistributionName,'Density',method.minsearch); 
% Weibull
DistributionName = 'Weibull';
[p_Weibull,X2_Weibull] = minsearch(parameters,Data,DistributionName,'Density',method.minsearch); 
% Normal
DistributionName = 'Normal';
[p_normal,X2_normal] = minsearch(parameters,Data,DistributionName,'Density',method.minsearch); 
% Logistic
DistributionName = 'Logistic';
[p_logistic,X2_logistic] = minsearch(parameters,Data,DistributionName,'Density',method.minsearch); 

%% Plot and table

% renormalize distribution and parameters
p_exponential(1) = p_exponential(1)/Vnorm; 
p_Weibull(1) = p_Weibull(1)/Vnorm; 
p_normal(1) = p_normal(1)/Vnorm; 
p_logistic(1) = p_logistic(1)/Vnorm; 
% n_lin_dim = n_lin./sampleNew.px2m./sampleNew.px2m;
% p_exponential(1) = p_exponential(1)/sampleNew.px2m/sampleNew.px2m; 
% p_Weibull(1) = p_Weibull(1)/sampleNew.px2m/sampleNew.px2m; 
% p_normal(1) = p_normal(1)/sampleNew.px2m/sampleNew.px2m; 
% p_logistic(1) = p_logistic(1)/sampleNew.px2m/sampleNew.px2m; 

figure(Idx)

x0=1000;
y0=500;
width=1000;
height= 400;        
set(gcf,'units','points','position',[x0,y0,width,height])
set(gcf,'color','w');

subplot(1,2,1)

bar(bin_centers,n_lin)

hold on
if strcmp(Mtype(1),'2D')
    %xdim = 1e-12;
    xlab_str = 'log_{10}(v), v = particle area (m^2)';
    ylab_str = 'Number density (n(v)/(m^{2}log_{10}(v))';
else
    %xdim = 1e-18;
    xlab_str = 'log_{10}(v), v = particle volume (m^3)';
    ylab_str = 'Number density (n(v)/(m^{3}log_{10}(v))';
end
xgrid = linspace(min(bin_centers)-2,max(bin_centers)+1,100);  %log10(logspace(0,9,100)'*xdim); 
plot(xgrid,exponentialDensity(p_exponential,xgrid),'b',...
    xgrid,WeibullDensity(p_Weibull,xgrid),'r',...
    xgrid,normalDensity(p_normal,xgrid),'k',...
    xgrid,logisticDensity(p_logistic,xgrid),'m');
legend('Data','Exponential','Weibull','Normal','Logistic')
xlabel(xlab_str)
ylabel(ylab_str)

% Table
fig = uifigure("Position",[800 100 480 150]);

uit = uitable(fig,"Position",[20 20 440 130],...
              "Data",{'Exponential' X2_exponential p_exponential(1) p_exponential(2) ''; ...
                      'Weibull'  X2_Weibull p_Weibull(1) p_Weibull(2) p_Weibull(3); ...
                      'Normal'  X2_normal p_normal(1) p_normal(2) p_normal(3); ...
                      'Logistic'  X2_logistic p_logistic(1) p_logistic(2) p_logistic(3); ...
                      }); 

vars = {"Distribution";strcat(char(967),char(178));char(945);char(957); char(963)};
set(uit,"ColumnName",vars)
sb = uistyle('FontColor','b');
sr = uistyle('FontColor','r');
sk = uistyle('FontColor','k');
sg = uistyle('FontColor','m');
addStyle(uit,sb,'row',1);addStyle(uit,sr,'row',2);addStyle(uit,sk,'row',3);addStyle(uit,sg,'row',4)

tableData = get(uit, 'Data');
columnNames = get(uit, 'ColumnName');
baseTableName = sprintf('DensityBasedFitting_%s',num);
fullTablename = fullfile(RD,baseTableName);
save(fullTablename, 'tableData', 'columnNames');
T = cell2table(tableData, 'VariableNames', columnNames);
fullTablename_csv = fullfile(RD,[baseTableName,'.csv']);
writetable(T, fullTablename_csv, 'Delimiter', '\t', 'WriteVariableNames', true);
drawnow;
fullUitablename = fullfile(RD,[baseTableName,'.png']);
exportapp(fig, fullUitablename);

X2 = [X2_exponential; X2_Weibull; X2_normal; X2_logistic];
Alpha = [ p_exponential(1); p_Weibull(1); p_normal(1); p_logistic(1)]; 
Mu =  [ p_exponential(2); p_Weibull(2); p_normal(2); p_logistic(2)]; 
Sigma = [ 0; p_Weibull(3); p_normal(3); p_logistic(3)]; 

end
