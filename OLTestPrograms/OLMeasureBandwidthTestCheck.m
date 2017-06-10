theBandwidths = 2.^(0:7);
nBandwidths = length(theBandwidths);

for i = 1:nBandwidths
    fwhmMeas(i) = fwhm(SToWls([380 2 201]), cals{end}.raw.bandwidthMeas(:, i), 0);
end

subplot(2, 2, 1);
plot(SToWls([380 2 201]), cals{end}.raw.bandwidthMeas)
xlabel('Wavelength');
ylabel('Power');
pbaspect([1 1 1]);

subplot(2, 2, 2);
plot(SToWls([380 2 201]), cals{end}.raw.bandwidthMeas./repmat(max(cals{end}.raw.bandwidthMeas), 201, 1))
xlabel('Wavelength');
ylabel('Power');
pbaspect([1 1 1]);

subplot(2, 2, 3);
plot(log2(theBandwidths), fwhmMeas, '-ok', 'MarkerFaceColor', 'k')
xlabel('log_2 mirror bandwidth');
ylabel('FWHM [nm]');
pbaspect([1 1 1]);

savefig('BandwidthTest.png', gcf, 'png');