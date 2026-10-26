function runBubbleProperties(measureData,sample,method)

addpath(genpath('BubbleProperties'));

checkInputProperties(measureData,sample,method)

%% Create directories

RD = sprintf(measureData.outputDir);
if ~exist(RD,'dir'); mkdir(RD); end
RDStat=  fullfile(RD,'Statistics');
if ~exist(RDStat,'dir'); mkdir(RDStat); end

%% Call bubbleProperties

for i = 1:numel(measureData.inputFile)

    X2d = zeros(4,numel(measureData.inputFile)); X2e = zeros(4,numel(measureData.inputFile));
    Alphad = zeros(4,numel(measureData.inputFile));
    Mud = zeros(4,numel(measureData.inputFile)); Mue = zeros(4,numel(measureData.inputFile));
    Sigmad = zeros(4,numel(measureData.inputFile)); Sigmae = zeros(4,numel(measureData.inputFile));
    sampleNew= struct();
    sampleNew.Depth = zeros(1,numel(measureData.inputFile{i}));
    sampleNew.Area = zeros(1,numel(measureData.inputFile{i}));
    sampleNew.px2m = zeros(1,numel(measureData.inputFile{i}));
    bubbleDim = cell(1,numel(measureData.inputFile{i}));
    num = zeros(1,numel(measureData.inputFile{i}));
    Mtype = strings(1,numel(measureData.inputFile{i}));

    % iterate over measurements to be combined
    disp(' ')
    for j = 1:numel(measureData.inputFile{i})
        filenameij = fullfile(measureData.inputDir,measureData.inputFile{i}{j});
        numC = regexp(filenameij, '\d+', 'match');
        num(j) = str2double(numC{end});
        if exist(filenameij,'file') == 2
            disp(measureData.inputFile{i}{j})
            disp(' ')
            load(filenameij,'bubbleTable');
        else
            error('File %s does not exist.', filenameij);
        end
        switch measureData.type{i}{j}
            case '3D'
                sampleNew.Depth(j) = sample.D{i}{j};
                bubbleDim{j} = 1/6*pi*bubbleTable.EquivDiameter.^3;
            case '2D'
                % iterate for Idx and create bubbleDim matrix
                sampleNew.Depth(j) = 1;
                bubbleDim{j} = pi/4*bubbleTable.EquivDiameter.^2;
            case '3Dstereo'
                sampleNew.Depth(j) = mean(bubbleTable.EquivDiameter);
                bubbleDim{j} = 1/6*pi*bubbleTable.EquivDiameter.^3;
        end
        sampleNew.Area(j) = sample.cropArea{i}{j};
        sampleNew.px2m(j) = sample.px2m{i}{j};

        Mtype(j) = measureData.type{i}{j};
    end
    
    numStr = strjoin(string(num), '_');

    [X2d(:,i),X2e(:,i),Alphad(:,i),Mud(:,i),Mue(:,i),Sigmad(:,i),Sigmae(:,i)] = bubbleProperties(bubbleDim,sampleNew,method,RDStat,i,numStr,Mtype);

    baseFigName = sprintf('Statistics_%s.png',numStr);
    fullFigname = fullfile(RDStat,baseFigName);
    exportgraphics(gcf,fullFigname)

end

%% Plot

% colors = {'b','r','k','m'};
% labels = {'Exponential','Weibull','Normal','Logistic'};
% gi = 1:numel(measureData.inputFile);
% 
% %
% figure
% 
% x0=400;
% y0=500;
% width=300;
% height= 400;        
% set(gcf,'units','points','position',[x0,y0,width,height])
% set(gcf,'color','w');
% 
% for i = 1:4
%     subplot(2,1,1)
%     plot(gi,X2d(i,:),'o-','Color',colors{i},'MarkerSize', 10)
%     ylabel(strcat(char(967),char(178)))
%     xlabel('Images')
%     xlim([min(gi)-0.2 max(gi)+0.2])
%     xticks(gi)
%     hold on
% 
%     subplot(2,1,2)
%     plot(gi,X2e(i,:),'+--','Color',colors{i},'MarkerSize', 10)
%     ylabel(strcat(char(967),char(178)))
%     xlabel('Images')
%     xlim([min(gi)-0.2 max(gi)+0.2])
%     xticks(gi)
%     hold on
% end
% x_limits = xlim; 
% y_limits = ylim; 
% x_text = x_limits(2) - 0.1 * range(x_limits); 
% y_text_start = y_limits(2) - 0.1 * range(y_limits);
% for i = 1:4
%     y_text = y_text_start - (i - 1) * (range(y_limits) / 12);
%     text(x_text, y_text, labels{i}, 'Color', colors{i}, 'FontSize', 9, 'HorizontalAlignment', 'right');
% end
% 
% baseFigName = sprintf('Statistics_X2.png');
% fullFigname = fullfile(RDStat,baseFigName);
% exportgraphics(gcf,fullFigname)

%
% figure
% 
% x0=10;
% y0=500;
% width=300;
% height= 600;
% set(gcf,'units','points','position',[x0,y0,width,height])
% set(gcf,'color','w');
% 
% for i = 1:4
%     subplot(3,1,1)
%     plot(gi,Alphad(i,:),'o-','Color',colors{i},'MarkerSize', 10)
%     ylabel(char(945))
%     xlabel('Images')
%     xlim([min(gi)-0.2 max(gi)+0.2])
%     xticks(gi)
%     hold on
% 
%     subplot(3,1,2)
%     plot(gi,Mud(i,:),'o-','Color',colors{i},'MarkerSize', 10)
%     hold on
%     plot(gi,Mue(i,:),'+--','Color',colors{i},'MarkerSize', 10)
%     ylabel(char(956))
%     xlabel('Images')
%     xlim([min(gi)-0.2 max(gi)+0.2])
%     xticks(gi)
%     hold on
% 
%     subplot(3,1,3)
%     plot(gi,Sigmad(i,:),'o-','Color',colors{i},'MarkerSize', 10)
%     hold on
%     plot(gi,Sigmae(i,:),'+--','Color',colors{i},'MarkerSize', 10)
%     ylabel(char(963))
%     xlabel('Images')
%     xlim([min(gi)-0.2 max(gi)+0.2])  
%     xticks(gi)
%     hold on
% end
% x_limits = xlim; 
% y_limits = ylim; 
% x_text = x_limits(2) - 0.1 * range(x_limits); 
% y_text_start = y_limits(2) - 0.1 * range(y_limits);
% for i = 1:4
%     y_text = y_text_start - (i - 1) * (range(y_limits) / 12);
%     text(x_text, y_text, labels{i}, 'Color', colors{i}, 'FontSize', 9, 'HorizontalAlignment', 'right');
% end

%% Save figures

% baseFigName = sprintf('Statistics_parameters.png');
% fullFigname = fullfile(RDStat,baseFigName);
% exportgraphics(gcf,fullFigname)

end
