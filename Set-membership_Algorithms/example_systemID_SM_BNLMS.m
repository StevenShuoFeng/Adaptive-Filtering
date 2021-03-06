%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Example: System Identification                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                               %
%  In this example we have a typical system identification scenario. We want    %
% to estimate the filter coefficients of an unknown system given by Wo. In      %
% order to accomplish this task we use an adaptive filter with the same         %
% number of coefficients, N, as the unkown system. The procedure is:            %
% 1)  Excitate both filters (the unknown and the adaptive) with the signal      %
%   x. In this case, x is chosen according to the BPSK constellation.           %
%   The variance of x is 1.                                                     %
% 2)  Generate the desired signal, d = Wo' x + n, which is the output of the    %
%   unknown system considering some disturbance (noise) in the model. The       %
%   noise power is given by sigma_n2.                                           %
% 3)  Choose an adaptive filtering algorithm to govern the rules of coefficient %
%   updating.                                                                   %
%                                                                               %
%     Adaptive Algorithm used here: SM_BNLMS                                    %
%                                                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%   Definitions:
ensemble    = 100;                          % number of realizations within the ensemble
K           = 500;                          % number of iterations
H           = [0.32+0.21*j,-0.3+0.7*j,0.5-0.8*j,0.2+0.5*j].';
Wo          = real(H);                      % unknown system
sigma_n2    = 0.04;                         % noise power
N           = 4;                            % number of coefficients of the adaptive filter
gamma       = 1e-12;                        % small positive constant to avoid singularity
gamma_bar   = sqrt(5 * sigma_n2);           % upper bound for the error modulus


%   Initializing & Allocating memory:
W       = ones(N,(K+1),ensemble);   % coefficient vector for each iteration and realization; w(0) = [1 1 1 1].'
MSE     = zeros(K,ensemble);        % MSE for each realization
MSEmin  = zeros(K,ensemble);        % MSE_min for each realization
nUp     = zeros(1,ensemble);        % number of updates for each realization of the ensemble


%   Computing:
for l=1:ensemble,

    X       = zeros(N,1);               % input at a certain iteration (tapped delay line)
    d       = zeros(1,K);               % desired signal

    x        = sign(randn(K,1));                 % Creating the input signal - BPSK
    sigma_x2 = var(x);                           % signal power = 1
    n        = sqrt(sigma_n2)*(randn(K,1));      % real noise

    for k=1:K,

        X       =   [x(k,1)
                     X(1:(N-1),1)];              % input signal (tapped delay line)

        d(k)    =   (Wo'*X(:,1))+n(k);           % desired signal

    end

    S   =   struct('gamma_bar',gamma_bar,'filterOrderNo',(N-1),'initialCoefficients',...
                   W(:,1,l),'gamma',gamma);
    [y,e,W(:,:,l),nUp(1,l)]  =   SM_BNLMS(d,transpose(x),S);

    MSE(:,l)    =   MSE(:,l)+(abs(e(:,1))).^2;
    MSEmin(:,l) =   MSEmin(:,l)+(abs(n(:))).^2;

end


%   Averaging:
W_av = sum(W,3)/ensemble;
MSE_av = sum(MSE,2)/ensemble;
MSEmin_av = sum(MSEmin,2)/ensemble;
nUp_av = sum(nUp,2)/ensemble;
pUp_av = nUp_av/K  * 100;

fprintf('\n');
fprintf('The average number of updates performed by SM_BNLMS Algorithm was %3.2f (in a total of %i iterations) ;\n',nUp_av, K);
fprintf('Therefore, SM_BNLMS Algorithm updated only %f percent of the time.\n',pUp_av);
fprintf('\n');


%   Plotting:
figure,
plot(1:K,10*log10(MSE_av),'-k');
title('Learning Curve for MSE');
xlabel('Number of iterations, k'); ylabel('MSE [dB]');

figure,
plot(1:K,10*log10(MSEmin_av),'-k');
title('Learning Curve for MSEmin');
xlabel('Number of iterations, k'); ylabel('MSEmin [dB]');

figure,
subplot 211, plot(real(W_av(1,:))),...
title('Evolution of the 1st coefficient (real part)');
xlabel('Number of iterations, k'); ylabel('Coefficient');
subplot 212, plot(imag(W_av(1,:))),...
title('Evolution of the 1st coefficient (imaginary part)');
xlabel('Number of iterations, k'); ylabel('Coefficient');

