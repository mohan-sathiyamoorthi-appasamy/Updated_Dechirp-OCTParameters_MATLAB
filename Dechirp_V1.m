% Mirror Directory
function Dechirp_V1(mirrorRawDir)
%currentfolder = pwd;
%mirrorRawDir = 'D:\RawFile\Roll off Measurements - 16-09-20\Spectrometer C';
rawFiles = dir(fullfile(mirrorRawDir,'\*.raw'));
numberOfRawFiles = length(rawFiles);
AscanAnalysis = 1;
fnames = {rawFiles.name}';
DechirpGeneration = 1;
save = 1;
if(DechirpGeneration == 0)
  dechirpPath = strcat(mirrorRawDir,'\Result\');
end
%% Dechirp Generation 
if DechirpGeneration == 1
for iFile = 1:numberOfRawFiles
  fid = fopen(fullfile(mirrorRawDir,sprintf('Inf%04d.raw', iFile-1)), 'r');
  Reference = fread(fid,'int16','l'); 
  %% Reshape the interferogram.........
  Reference = reshape(Reference,[2048 1000 1]);
  Reference = Reference(:,:,1);
  Reference = Reference';
  singleFringe = Reference(1,:);
  maxFringe = max(singleFringe)/2;
  %thrMax = maxFringe +150;
  %thrMin = maxFringe -150;
  if (maxFringe - singleFringe(1500) < 500)
      disp('Good data');
  %% Fourier Transform
  PSF= fft(singleFringe);
  
  %% Select single Peak
  figure(1),plot(abs(PSF));
  [x1,~]=ginput(2);
  filt_fn = zeros (size (singleFringe, 2), 1); 
  filt_fn(x1(1):x1(2)) = 1;

  %% Filter the Single Peak
  singlePeak = PSF .*filt_fn';
  
  %% IFFT
  filteredSignal = ifft(singlePeak);
  
  %% Phase of Filtered Signal
  phaseOCT(iFile,:) = unwrap(angle(hilbert(imag(filteredSignal))));
  figure(2),plot(phaseOCT(iFile,:)),xlabel('Pixels'),ylabel('Phase'),title('Phase of Mirror Reflectivity');
  saveas(gcf,sprintf('PhaseImage%d.png',iFile));
  %% Phase Normalization
  normPhase = phaseOCT(iFile,:)./max(phaseOCT(iFile,:));
  
  %% Sampling Points
  samplingPoints = 2048;
  allNormPhase(iFile,:) = normPhase.*samplingPoints;
  else
      disp('Bad Data');
     % break;
  end
end 

%% Average Phase
avgNormPhase = mean(allNormPhase,1);

%% Re-Scaling of Average Phase
for itr = 1:size(Reference,2)
  
  avgPhaseRescale(itr) = min(avgNormPhase)+((max(avgNormPhase)-min(avgNormPhase))/size(Reference,2))*(itr-1);
  
end 

end
%% Interpolation or Resampling 
nCameraPixels = 2048;
x = 1:nCameraPixels;
dechirpData = interp1(avgNormPhase,x,avgPhaseRescale,'spline');
dechirpData(dechirpData<0) = 0;
%% Save Dechirp File in Text Format
if save == 1
T = table(dechirpData');
dechirpFolder = strcat(mirrorRawDir,'\Result\');
dechirpPath = dechirpFolder;
mkdir(dechirpFolder);
cd(dechirpFolder);
fid = fopen ('mn_R&D_OEM_System.txt', 'w+');
fprintf (fid, '%5.4f\t', T.Var1);
fclose (fid);
%% Save in Excel Format
xlswrite('mn_V1.xls', dechirpData');
msgbox('Dechirp File is Generated');
end