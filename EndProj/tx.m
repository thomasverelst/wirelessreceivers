function [txsignal conf] = tx(txbits,conf,k)
% Digital Transmitter
%
%   [txsignal conf] = tx(txbits,conf,k) implements a complete transmitter
%   consisting of:
%       - modulator
%       - pulse shaping filter
%       - up converter
%   in digital domain.
%
%   txbits  : Information bits
%   conf    : Universal configuration structure
%   k       : Frame index
%

%% TODO preamble?

%% Conver to QPSK
tx = mapper(txbits, conf.modulation_order);

%% Convert to parallel
n_samples = ceil(length(tx)/conf.n_carriers)

txzeros = zeros(1, conf.n_carriers*n_samples);
txzeros(1:length(tx)) = tx;

a = zeros(conf.n_carriers, n_samples); % Matrix with OFDM symbols
% TODO beter met reshape https://www.mathworks.com/matlabcentral/answers/64801-how-to-convert-binary-data-from-serial-to-parallel

for i = 1:n_samples
    a(:, i) = txzeros((i-1)*conf.n_carriers+1: i*conf.n_carriers);
end

%% Convert with IDFT operation
ttt =  conf.n_carriers * conf.os_factor;
s = zeros((1+conf.cpref_length) * (ttt), n_samples);
for i = 1:n_samples
   ifft = osifft(a(:, i), conf.os_factor);
   s(:, i) = [ifft(end - conf.cpref_length*ttt+1: end); ifft]; % immediately insert cyclic prefix
end

%% Convert to serial
s = s(:);


%%%%% RECEIVER

r = s;

%% Serial to parallel
symbol_length = (1+conf.cpref_length)*conf.n_carriers*conf.os_factor;
n_samples = floor(length(r)/symbol_length);
rx = reshape(r, [ symbol_length  n_samples]);

%% Delete cyclic prefix
rx = rx(conf.cpref_length*conf.n_carriers*conf.os_factor+1: end, :);

%% FFT
rxs = zeros(conf.n_carriers, n_samples);
for i = 1:n_samples
   rxs(:, i) = osfft(rx(:,i), conf.os_factor);
end


%% Serial
rxs = rxs(:);

%% Demap
rxbits = demapper(rxs, 2); % DEMAP QPSK









error ('stop here')
% 
% 
% 
% 
% for i = 1:conf.n_carriers:length(txbits)-conf.n_carriers
%     a(i, :) = txbits(i:i+conf.n_carriers-1);
% end
% a
%     
% 
% 
% 
% % 
% 
% 
% 
% 
% 
% 
% 
% % dummy 400Hz sinus generation
% %time = 1:1/conf.f_s:4;
% %txsignal = 0.3*sin(2*pi*400 * time.');
% 
% preamble_bpsk = (1 - 2 * lfsr_framesync(conf.npreamble));
% tx = [preamble_bpsk; mapper(txbits, conf.modulation_order)];
% 
% %oversample
% tx = upsample(tx, conf.os_factor);
% 
% % Shape the symbol diracs with pulse
% txsignal = conv(tx, conf.h.','same');
% 
% % Upconvert
% time = 0:1/conf.f_s: (length(txsignal) -1)/conf.f_s;
% txsignal = real(txsignal .* exp(1j*2*pi*conf.f_c * time.'));