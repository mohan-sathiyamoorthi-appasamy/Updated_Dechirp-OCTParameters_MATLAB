function spectrometerData = readOCTrawFile(inputRawFile)
  fid = fopen (inputRawFile, 'r');
  bScanCameraRawDataStream = fread (fid, 'int16', 'l');
  spectrometerData = reshape (bScanCameraRawDataStream, [2048,1000]);
  fclose(fid);
end
