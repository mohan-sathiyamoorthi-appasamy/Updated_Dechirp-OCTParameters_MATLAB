%% PSF & Sensitivity Roll -off
function OCTSystemParameter(InfRawDir,MovandRefArmDir, dechirpTextFile)
    dechirpData = load(dechirpTextFile);
    nCameraPixels = 2048;
    rawFiles = dir(fullfile(InfRawDir,'\*.raw'));
    numberOfRawFiles = length(rawFiles);

for iPosition = 1:numberOfRawFiles
    interferencePatternFileName = sprintf ('Inf%04d.raw', (iPosition-1));
    movingArmFileName = sprintf ('Mov%04d.raw', (iPosition-1));
    refArmFileName = sprintf ('Ref%04d.raw', (iPosition-1));
    
    % Read files for different patterns
    interferenceRawData = readOCTrawFile (fullfile (InfRawDir, interferencePatternFileName));
    movingArmRawData = readOCTrawFile (fullfile (MovandRefArmDir, movingArmFileName));
    avgmovingArmRawData = mean (movingArmRawData, 2);
    
    refArmRawData = readOCTrawFile (fullfile (MovandRefArmDir, refArmFileName));
    avgrefArmRawData = mean (refArmRawData, 2);
    
    meanSpectra = (avgmovingArmRawData+avgrefArmRawData);
    %%  Background Subtraction
    fringe=interferenceRawData(:,1)- meanSpectra;
   
   
    %%  Interpolation accordance with corrected resampled function
    vq=interp1(fringe,dechirpData,'spline','extrap');
    
    %%   FFT of Windowed Data & crop it
    window = hann(nCameraPixels);
    dataPSF2= fft(vq'.*window);
    
    calibratedPSF = abs(dataPSF2);
    unCalibratedPSF = abs(fft(fringe));
    
    %%  PSF & Sensitivity Roll - off
    xScaleRange2 = (1 : nCameraPixels/2).*4.9/1000;
    figure(2),plot(xScaleRange2,calibratedPSF(1 : nCameraPixels/2),'b'),hold on,
    plot(xScaleRange2,unCalibratedPSF(1 : nCameraPixels/2),'r'), xlabel('Position in mm'),ylabel('Amplitude'),title('PSF'),legend('Calibrated PSF','UnCalibrated PSF');
    figure(3),plot(xScaleRange2,20*log10(calibratedPSF(1 : nCameraPixels/2))),hold on, xlabel('Position in mm'),ylabel('Amplitude in dB'),title('Sensitivity Roll-off');
    
    %% Axial Resolution
    gf1 = fit((1:length(calibratedPSF(1 : nCameraPixels/2)))',((calibratedPSF(1 : nCameraPixels/2)).^2)','gauss1');
    tmp     = coeffvalues(gf1);
    x1      = tmp(3);
    fprintf('\nAxial Resolution of Fringe %d: %f\n',iPosition,x1*1.665);
end