clc;
clear;
close all;
fprintf('Gaussian Secure Key Generation + AWGN Simulation \n');
N = 1000000;
mu = 0;
sigma = 1;
gaussian_alice = mu + sigma*randn(1,N);
x = linspace(-4,4,2000);
pdf_curve = (1/(sigma*sqrt(2*pi))) * exp(-(x-mu).^2/(2*sigma^2));
figure(1);
histogram(gaussian_alice,80,'Normalization','pdf'); hold on;
plot(x,pdf_curve,'LineWidth',3);
title('Fig 1: Gaussian Histogram vs PDF');
xlabel('Value'); ylabel('Density');
grid on;
fprintf('Gaussian samples generated\n');
key_alice = uint8(gaussian_alice > 0);
gaussian_bob = gaussian_alice;
key_bob = uint8(gaussian_bob > 0);
KDR = mean(key_alice ~= key_bob);
fprintf('Key Disagreement Rate = %.5f\n', KDR);
plaintext  = uint8(randi([0 1],1,N));
ciphertext = bitxor(plaintext, key_alice);
decrypted  = bitxor(ciphertext, key_bob);
if isequal(plaintext,decrypted)
    disp('✔ Perfect Decryption');
else
    disp('✖ Decryption Failed');
end
p = mean(key_alice);
entropy_key = -p*log2(p)-(1-p)*log2(1-p);
fprintf('Gaussian Key Entropy = %.4f bits\n', entropy_key);

plaintext_flip = plaintext;
plaintext_flip(1) = ~plaintext_flip(1);
ciphertext_flip = bitxor(plaintext_flip, key_alice);
avalanche = sum(ciphertext ~= ciphertext_flip)/N * 100;
fprintf('Avalanche Effect = %.2f %%\n', avalanche);

gaussian_eve = randn(1,N);
key_eve = uint8(gaussian_eve > 0);
eve_decrypt = bitxor(ciphertext, key_eve);
ber_eve = mean(eve_decrypt ~= plaintext);
fprintf('Eavesdropper BER = %.4f (≈0.5 secure)\n', ber_eve);

figure(2);
scatter(gaussian_alice(1:2000), gaussian_bob(1:2000), '.');
title('Fig 2: Alice–Bob Correlation');
xlabel('Alice'); ylabel('Bob');
grid on;

lfsr_key = uint8(randi([0 1],1,N));
p2 = mean(lfsr_key);
entropy_lfsr = -p2*log2(p2)-(1-p2)*log2(1-p2);
figure(3);
bar([entropy_lfsr entropy_key]);
set(gca,'XTickLabel',{'LFSR','Gaussian'});
title('Fig 3: Entropy Comparison');
grid on;

noise_levels = 0:0.1:2;
ber = zeros(size(noise_levels));

bpsk = 2*double(key_alice) - 1;
for i = 1:length(noise_levels)

    noise = noise_levels(i) * randn(1,N);

    rx = bpsk + noise;     

    detected = uint8(rx > 0);

    ber(i) = mean(detected ~= key_alice);
end

figure(4);
plot(noise_levels, ber,'o-','LineWidth',2);
xlabel('Noise STD');
ylabel('BER');
title('Fig 4: BER vs Noise (AWGN Channel)');
grid on;

key_centered = double(key_alice) - mean(key_alice);
auto = xcorr(key_centered,50,'coeff');
figure(5);
stem(auto);
title('Fig 5: Key Autocorrelation');
xlabel('Lag (k)');
ylabel('Autocorrelation R(k)');
grid on;

writematrix(gaussian_alice','alice_gaussian.csv');
writematrix(key_alice','alice_key.csv');
fprintf('Simulation Completed Successfully \n');