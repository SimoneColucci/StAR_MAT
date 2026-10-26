function [X2,Mu,Sigma] = exceedanceBasedAnalysis(v,sampleNew,method,RD,Idx,num,Mtype)

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
bin_edges = linspace(min([log10v{:}]),max([log10v{:}]),22);%22
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
sigma_array = cell(1,Nm);
Sprime_array = cell(1,Nm);
Vtot = sampleNew.Depth.*sampleNew.Area.*sampleNew.px2m.*sampleNew.px2m;
Vtot = Vtot(Idx_sorted);
rho = zeros(1,Nm);
for j = 1:Nm
    n = histcounts( log10v{j},bin_edges( Il_new(j):Ir_new(j) ) );
    n0 = sum(n); 
    n1 = fliplr(cumsum(fliplr(n)));
    n2 = n0 - n1;
    sigma_array{j} = sqrt( n1.*n2.*(sqrt(n1)+sqrt(n2)).^2./n0^4 ); 
    Sprime_array{j} =fliplr(cumsum(fliplr(n))/sum(n));
    rho(j) = sum(n)/Vtot(j);
end
w = zeros(1,Nm);
for j = 1:Nm
    w(j) = rho(j)/sum(rho);
    %sigma_array{j} = sigma_array{j}*w(j);
    Sprime_array{j} = Sprime_array{j}*w(j);
end
sigma = [sigma_array{:}];
sigma(Ir_new(1:end-1)) = sigma(Ir_new(1:end-1)+1);
Sprime = [Sprime_array{:}];

%% Fitting    
Data.x = 10.^(bin_centers);
Data.y = Sprime;
Data.sigma = sigma;

% n0 = sum(n); % n0 = n1+n2
% n1 = fliplr(cumsum(fliplr(n)));
% n2 = n0 - n1;
% Data.sigma = sqrt( n1.*n2.*(sqrt(n1)+sqrt(n2)).^2./n0^4 );
Data.sigma(1) = 1; Data.sigma(end) = 1;

parameters.lowBound =  [( min([log10v{:}]) ) 1e-10];
parameters.highBound = [(max([log10v{:}])) 1]; 

disp('#### Fitting based on exceedance ####')
% Exponential
DistributionName = 'Exponential';
[p_exponential,X2_exponential] = minsearch(parameters,Data,DistributionName,'Exceedance',method.minsearch); 
% Weibull
DistributionName = 'Weibull';
[p_Weibull,X2_Weibull] = minsearch(parameters,Data,DistributionName,'Exceedance',method.minsearch); 
% Normal
DistributionName = 'Normal';
[p_normal,X2_normal] = minsearch(parameters,Data,DistributionName,'Exceedance',method.minsearch); 
% Logistic
DistributionName = 'Logistic';
[p_logistic,X2_logistic] = minsearch(parameters,Data,DistributionName,'Exceedance',method.minsearch); 

%% Plot

figure(Idx)

subplot(1,2,2)

bar(bin_centers,Sprime)

hold on
if strcmp(Mtype(1),'2D')
    %xdim = 1e-12;
    xlab_str = 'log_{10}(v), v = particle area (m^2)';
else
    %xdim = 1e-18;
    xlab_str = 'log_{10}(v), v = particle volume (m^3)';
end
xgrid = 10.^(linspace(min(bin_centers)-2,max(bin_centers)+1,100)); %logspace(0,9,100)'*xdim; 
plot(log10(xgrid),exponentialExceedance(p_exponential,xgrid),'b',...
    log10(xgrid),WeibullExceedance(p_Weibull,xgrid),'r',...
    log10(xgrid),normalExceedance(p_normal,xgrid),'k',...
    log10(xgrid),logisticExceedance(p_logistic,xgrid),'m');
legend('Data','Exponential','Weibull','Normal','Logistic')
xlabel(xlab_str)
ylabel('Exceedance')

% Table
fig = uifigure("Position",[1400 100 460 150]);

uit = uitable(fig,"Position",[20 20 420 130],...
              "Data",{'Exponential' X2_exponential p_exponential(1) ''; ...
                      'Weibull'  X2_Weibull p_Weibull(1) p_Weibull(2); ...
                      'Normal'  X2_normal p_normal(1) p_normal(2); ...
                      'Logistic'  X2_logistic p_logistic(1) p_logistic(2); ...
                      }); 

vars = {"Distribution";strcat(char(967),char(178));char(957); char(963)};
set(uit,"ColumnName",vars)
sb = uistyle('FontColor','b');
sr = uistyle('FontColor','r');
sk = uistyle('FontColor','k');
sg = uistyle('FontColor','m');
addStyle(uit,sb,'row',1);addStyle(uit,sr,'row',2);addStyle(uit,sk,'row',3);addStyle(uit,sg,'row',4)

tableData = get(uit, 'Data');
columnNames = get(uit, 'ColumnName');
baseTableName = sprintf('ExceedanceBasedFitting_%s',num);
fullTablename = fullfile(RD,baseTableName);
save(fullTablename, 'tableData', 'columnNames');
T = cell2table(tableData, 'VariableNames', columnNames);
fullTablename_csv = fullfile(RD,[baseTableName,'.csv']);
writetable(T, fullTablename_csv, 'Delimiter', '\t', 'WriteVariableNames', true);
drawnow;
fullUitablename = fullfile(RD,[baseTableName,'.png']);
exportapp(fig, fullUitablename);

X2 = [X2_exponential; X2_Weibull; X2_normal; X2_logistic];
Mu =  [ p_exponential(1); p_Weibull(1); p_normal(1); p_logistic(1)]; 
Sigma = [ 0; p_Weibull(2); p_normal(2); p_logistic(2)]; 

end
