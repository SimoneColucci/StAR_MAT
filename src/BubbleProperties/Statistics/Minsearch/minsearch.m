function [pfitBest,ChiSquareBest] = minsearch(parameters,Data,DistributionName,BranchName,minsearchMethod)

Data.distributionName = DistributionName;
Data.branchName = BranchName;

disp(['Fitting data with ',DistributionName,' distribution'])

switch minsearchMethod

    case 'fmincon'
        %options = optimset('TolFun',1e-15,'TolX',1e-15,'MaxFunEvals',2000,'MaxIter',2000,'Algorithm','interior-point','Display','off','ScaleProblem', true);
        options = optimoptions('fmincon', 'Algorithm', 'interior-point', 'ScaleProblem', true,'StepTolerance', 1e-15, 'ConstraintTolerance', 1e-15,'Display','off');

        pmean = parameters.lowBound + abs(parameters.lowBound-parameters.highBound)./2;
        psigma =  abs(pmean - parameters.lowBound)./2;
   
        pfit = zeros(100,numel(parameters.lowBound)); ChiSquare = zeros(100,1); fitFlag = zeros(100,1);
        for i= 1:100
            % fmincon starting points
            pstart= normrnd(pmean,psigma);
            [BF,fval,exitflag]= fmincon(@(VAR) ChiSquareFun(VAR,Data),...
                pstart,[],[],[],[],...
                parameters.lowBound,parameters.highBound,[],options);

            pfit(i,:) = BF;
            ChiSquare(i) = fval;
            fitFlag(i) = exitflag;

        end

        [ChiSquareBest, I] = min(ChiSquare);
        pfitBest = pfit(I,:);


    case 'simplex'
        [pfitBest,ChiSquareBest] = simplex( @ChiSquareFun, numel(parameters.lowBound), ...
            'additionalData',Data,...
            'lowBoundary', parameters.lowBound,...
            'highBoundary', parameters.highBound,...
            'plot',false );

end



%% Chi square per degrees of freedom
function ChiSquareTilde = ChiSquareFun(fitParameters,Data)

switch Data.branchName

    case 'Density'
        switch Data.distributionName
            case 'Exponential'
                Model = exponentialDensity(fitParameters,Data.x);
                Np = 2;
            case 'Weibull'
                Model = WeibullDensity(fitParameters,Data.x);
                Np = 3;
            case 'Normal'
                Model = normalDensity(fitParameters,Data.x);
                Np = 3;
            case 'Logistic'
                Model = logisticDensity(fitParameters,Data.x);
                Np =3;
        end
    case 'Exceedance'
        switch Data.distributionName
            case 'Exponential'
                Model = exponentialExceedance(fitParameters,Data.x);
                Np = 1;
            case 'Weibull'
                Model = WeibullExceedance(fitParameters,Data.x);
                Np = 2;
            case 'Normal'
                Model = normalExceedance(fitParameters,Data.x);
                Np = 2;
            case 'Logistic'
                Model = logisticExceedance(fitParameters,Data.x);
                Np =2;
        end
end

ChiSquareF =  sum( ( (Model - Data.y)./max(1e-10,Data.sigma)).^2 );
ChiSquareTilde = ChiSquareF./(numel(Data.x)-Np);
% if isnan(ChiSquareF) 
%     Data.branchName
%     Data.distributionName
%     Model
%     Data.y
%     Data.sigma
% end    


