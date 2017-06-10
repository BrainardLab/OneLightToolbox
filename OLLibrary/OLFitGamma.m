function [fit_out,x,fitComment] = OLFitGamma(values_in,measurements,values_out,fitType)
% [fit_out,x,fitComment] = OLFitGamma(values_in,measurements,values_out,fitType)
%
% This is like PTB FitGamma with some restrictions for OneLight, plus some additional
% fit options pulled out of CalibrateFitGamma. The PTB stuff has grown crufty over the
% years and we are paying the price for that by having to port over something we
% need in a hurry.
%
% fitType:
%   Numeric values are passed through to PTB function FitGamma.
%   String values:
%     'betacdf' - Fit with a double betacdf (that is, a betacdf of a betacdf;
%     'betacdfnr' - Apply a normalized Naka-Rushton function to the double betacdf;
%     'betacdfpiecelin' - The input to the double betacdf is passed through a two piece
%         linear function with control points (0,0), (1,1), and fit parameters (x,y). 
%     'betacdfquad' - The input to the double betacdf is passed through a quadratic function
%         with control points (0,0), (1,1), and and fit parameters (x,y).       
%
% 3/14/14  dhb, ms  Cobbled together.
% 
if (size(measurements,2) > 1)
    error('Only know how to deal with one band at a time.  Sorry.');
end

if (ischar(fitType))
    switch (fitType)
        case {'betacdf','betacdfnr','betacdfpiecelin','betacdfquad'}
            if (~exist('fit','file'))
                error('Fitting with the betacdf requires the curve fitting toolbox\n');
            end
            if (~exist('betacdf','file'))
                error('Fitting with the betacdf requires the stats toolbox\n');
            end
            mGammaMassaged = MakeGammaMonotonic(HalfRect(measurements));
                        
            % Fmincon here we come    
            a = 1;
            b = 1;
            c = 1;
            d = 1;
            e = 1;
            f = 1;
            g = 0.5;
            h = 0.5;
            x0 = [a b c d e f g h];
            vlb = [1e-3 1e-3 1e-3 1e-3 1e-3 1e-3 0.1 0.1];
            vub = [1e3 1e3 1e3 1e3 1e3 1e3 0.9 0.9];
            
            % Fit and predictions
            options = optimset('fmincon');
            options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set');
            x = fmincon(@(x)BetaCdfFun(x,fitType,values_in,mGammaMassaged),x0,[],[],[],[],vlb,vub,[],options);
            fit_out = ComputeBetaCdf(x,fitType,values_out);
            fitComment = sprintf('% option of OLFitGamma',fitType);
            
        case 'linearinterpolation'
            [fit_out,x,fitComment] = FitGamma(values_in,measurements,values_out,6);
            
        otherwise
            error('Unknown gamma fit type passed');
    end
else
    [fit_out,x,fitComment] = FitGamma(values_in,measurements,values_out,fitType);
end

end

function f = BetaCdfFun(x,fitType,input,gamma)

pred = ComputeBetaCdf(x,fitType,input);
diff = gamma-pred;
f = sqrt(mean(diff.^2));

end

function pred = ComputeBetaCdf(x,fitType,input)
a = x(1);
b = x(2);
c = x(3);
d = x(4);
e = x(5);
f = x(6);
g = x(7);
h = x(8);

switch (fitType)
    case 'betacdf'
        % Betacdf of betacdf
        input(input < 0) = 0;
        input(input > 1) = 1;
        pred = betacdf(betacdf(input.^f,a,b).^e,c,d);
        
    case 'betacdfnr'
        % This was an attempt that involved adding
        % a Naka-Rushton sigmoid around the beta
        % cd version.  It didn't help the fit much.
        x1 = betacdf(betacdf(input.^f,a,b).^e,c,d);
        s = h.^g;
        x2 = x1.^g;
        x3 = x2./(x2+s);
        pred = x3*(1+s);
        
    case 'betacdfpiecelin'
        % Piecewise linear method
        %
        % The blur option didn't seem to work right when
        % blue > 0.  The smoothed quadratic version seems
        % better in any case. 
        blurSize = 0;
        pred = zeros(size(input));
        temp1 = (h/g)*input;
        temp1(temp1 < 0) = 0;
        temp1(temp1 > 1) = 1;
        pred1 = betacdf(betacdf(temp1.^f,a,b).^e,c,d);
        
        temp2 = h+((1-h)/(1-g))*(input-g);
        temp2(temp2 < 0) = 0;
        temp2(temp2 > 1) = 1;
        pred2 = betacdf(betacdf(temp2.^f,a,b).^e,c,d);
        
        index = find(input <= g-blurSize);
        pred(index) = pred1(index);
        
        index = find(input > g+blurSize);
        pred(index) = pred2(index);
        
        index = find(input > g-blurSize & input <= g+blurSize);
        lambda = (input - g)/(2*blurSize);
        pred(index) = (1-lambda(index)).*pred1(index) + lambda(index).*(pred2(index));
        
    case 'betacdfquad'
        % Find the quadratic that goes through (0,0), (g,h), and (1,1).
        % Remap input according to this quadratic.
        %
        % This provides a smooth version of the commentd out
        % piecewise linear method below.
        a1 = (h/g - g)/(1-g);
        b1 = 1 - a1;
        newinput = a1*input + b1*input.^2;
        newinput = abs(newinput);
        newinput(newinput < 0) = 0;
        newinput(newinput > 1) = 1;
        pred = betacdf(betacdf(newinput.^f,a,b).^e,c,d);
    otherwise
        error('Unknown fit type passed');
end



% Little figure that helped debug the code
% once upon a time.
%
% figure; clf; hold on
% plot(input,temp1,'r:');
% plot(input,temp2,'g:');
% plot(input,pred1,'r');
% plot(input,pred2,'g');
% plot(input,pred3,'b','LineWidth',2);
% plot(input,pred,'k');
% plot(input,newinput,'b:');





end
