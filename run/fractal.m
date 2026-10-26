% Apply the model of Otsuki (1998) (Eqn. 1) to fit the exceedance curve and
% calculate the power law exponent \beta (i.e., fractal index).
% ref.  Otsuki, K. (1998), Geophysical research letters, 25(5), 671-674.
clear all
close all
%% Input
% Path of main folder (corresponding to the path defined in PreProcess for the output folder)
mainFolderPath = '/home/simone/gitLabSync/StAR/python_2/';
subFolderNames = {'output'};
% Number of files per group (As defined in Properties, eventually inherited from PreProcess during a workflow)
Nimage = 2;
% Names to be displayed in the legend
legendNames{1,:} = {'CataclasiteA_micro','CataclasiteA_sample'};
% Data colors
red1 = [1 0 0]; red2 =  [0.6 0 0];
colors{1,:} = {red1,red2};
% Data symbols
symbols{1,:} = {'s','o'};
% Save figures
saveFig = false;
dpi=600;
%% Iterating over subFolders
Nplot=numel(subFolderNames);
txt = '';
for j = 1:Nplot
   %% Read Measurements
   file.dir =strcat(mainFolderPath,subFolderNames{j},'/Measurements/');
   fileInfo = dir(fullfile(file.dir, '*.csv'));
   file.name = {fileInfo.name};
   % read cropArea [pixels^2] and px2m [m/pixels]
   PreProcess_out = readtable(strcat(mainFolderPath,subFolderNames{j},'/preProcessingResults.csv'));
   for i = 1:Nimage
       cropArea(i) = PreProcess_out.(sprintf('cropArea_%d', i));
       px2m(i) = PreProcess_out.(sprintf('px2m_%d', i));
       fullFilename = fullfile(file.dir,file.name{i});
       Measurements_out = readtable(fullFilename);
       EquivDiameter_image{i} = Measurements_out.EquivDiameter;
       MaxFeretDiameter_image{i} = Measurements_out.MaxFeretDiameter;
       MajorAxisLength_image{i} = Measurements_out.MajorAxisLength;
       Circularity_image{i} = Measurements_out.Circularity;
       Eccentricity_image{i} = Measurements_out.Eccentricity;
       Solidity_image{i} = Measurements_out.Solidity;
       Orientation_image{i} = Measurements_out.Orientation;
   end
   %% Figures
   set(groot, 'defaultLineLineWidth', 2);
   %% Figure 2
   f2 = figure(2);
   x0=0;
   y0=500;
   width=700;
   height= 600;
   set(gcf,'units','points','position',[x0,y0,width,height])
   set(gcf,'color','w');
   n_tot = [];
   bin_centers_tot = [];
   Icolor_tot = [];
   for i = 1:Nimage
       log10D = log10(EquivDiameter_image{i});
       bin_edges = min(log10D):0.1:max(log10D);
       bin_centers_tot = [bin_centers_tot,bin_edges(1:end-1) + abs(diff(bin_edges))/2];
       Atot =  cropArea(i)*px2m(i)*px2m(i);
       n = histcounts(log10D,bin_edges);
       n_tot = [n_tot,n./Atot];
       Icolor_tot = [Icolor_tot,ones(1,numel(n))*i];
   end
   [bin_centers_s, Is] = sort(bin_centers_tot);
   n_tot_s = n_tot(Is);
   Sprime_s =fliplr(cumsum(fliplr(n_tot_s))/sum(n_tot_s));
   Icolor_tot_s = Icolor_tot(Is);
   for i = 1:Nimage
       Icolor = find(Icolor_tot_s==i);
       plot(bin_centers_s(Icolor)+6,log10(Sprime_s(Icolor)),cell2mat(symbols{j}(i)),'Color',cell2mat(colors{j}(1)),'DisplayName',cell2mat(legendNames{j}(i)))
       if (j==1 && i==1)
           xlabel('Log_{10} of equivalent diameter (\mum)')
           ylabel('Log_{10} of exceedance')
       end
       hold on
   end
   % Fitting
   p0 = [0.1, 0.1]; % initial parameters
   y = Sprime_s;
   I_notInf = find(abs(y)~=Inf);
   x = 10.^(bin_centers_s(I_notInf));
   y = y(I_notInf);
   plotColor = cell2mat(colors{j}(1));
   title('Select first point from which roll-off starts', ...
       'Color', plotColor, 'FontSize', 12, 'FontWeight', 'bold');
   [x_rolloff, y_rolloff] = selectPoint(x, y);
   ClickMatrix = [x_rolloff, y_rolloff] ; %[10^(xy_rollof(j,1)-6),10^(xy_rollof(j,2))]
   DataMatrix = [x', y'];
   [I, ~] = dsearchn(DataMatrix, ClickMatrix);
   if I<numel(x)
       x = x(1:I-1);
       y=y(1:I-1);
   end
   % Find/select cut-off (inflection) point
   selectMethod = questdlg('Cut-off point:', 'Cut-off point', 'Select point', 'Automatic search', 'Automatic search');
   if strcmp(selectMethod, 'Select point')
       title('Select cut-off point', ...
           'Color', plotColor, 'FontSize', 12, 'FontWeight', 'bold');
       [Dc, y_Dc] = selectPoint(x, y);
   else
       dy  = diff(y) ./ diff(x);
       d2y = diff(dy) ./ diff(x(2:end));
       x_d2 = x(2:end-1);
       sign_change = find(d2y(1:end-1) .* d2y(2:end) < 0);
       if ~isempty(sign_change)
           idx_flex = sign_change(1);
           x_flex = x_d2(idx_flex);
           y_flex = y(idx_flex+1);
           fprintf('Cut-off point found: x = %.4f, y = %.4f\n', x_flex,y_flex);
           Dc = x_flex;
           y_Dc = y_flex;
       else
           disp('Cut-off point not found!');
           title('Select cut-off point', ...
               'Color', plotColor, 'FontSize', 12, 'FontWeight', 'bold');
           [Dc, y_Dc] = selectPoint(x, y);
       end
   end
   fun = @(p, x) ( 1 + (x./(Dc) ).^p(1) ).^(-p(2)./p(1)) ;
   [p_fit,resnorm] = lsqcurvefit(fun, p0, x, y);
   y_fit = fun(p_fit, x);
   Y_media = mean(y);
   SS_tot = sum((y - Y_media).^2);
   R_squared = 1 - (resnorm / SS_tot);
   plot(log10(x)+6,log10(y_fit),'-k','DisplayName','Fitting function (Otsuki, 1998)','Color',plotColor);
   plot(log10(Dc)+6,log10(y_Dc),'+','Color',plotColor,'MarkerSize', 12, 'LineWidth', 2,'DisplayName','Cut-off point')
   txt = sprintf('\\alpha = %.3f, \\beta = %.3f, R^2 = %.4f\\newline', p_fit(1), p_fit(2), R_squared);
   y_start = 0.95;
   y_spacing = 0.05;
   y_new_pos = y_start - (j - 1) * y_spacing;
   text(0.95, y_new_pos, txt, ...
       'Units', 'normalized', ...
       'Interpreter', 'tex', ...
       'HorizontalAlignment', 'right', ...
       'VerticalAlignment', 'top', ...
       'FontSize', 10, ...
       'BackgroundColor', 'w', ...
       'EdgeColor',cell2mat(colors{j}(1)));
   lgd = legend('show'); % Show legend using DisplayName
   lgd.Interpreter='tex';
   lgd.Location = 'southwest'; % Set location
   lgd.Orientation = 'vertical'; % Set orientation
   lgd.FontSize = 8; % Set font size
   if (j==Nplot && saveFig); exportgraphics(f2,'Fig2.jpg','Resolution',dpi); end
end
