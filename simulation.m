%% 2013/10/28
% Rev 1: 2015/1/22 by Zibang Zhang
% Rev 2: 2016/6/23 by Zibang Zhang

%% simulating single-pixel imaging with phase-shifting sinusoid illumination
close all
clear all
clc

%% Parameters
nStepPS = 3;
Phaseshift = 120;
scale = 2;
Amplitude = 1;
SpectralCoverage = 1;
SamplingPath = 'circular';

% Get input image
[imgFile pathname] = uigetfile({'*.bmp;*.jpg;*.tif;*.png;*.gif'','...
    'All Image Files';'*.*','All Files'});
InputImg = im2double(imread([pathname imgFile]));
figure,imshow(InputImg);title('Input image'); axis image;

[mRowScale, nColScale] = size(InputImg);

mRow = mRowScale / scale;
nCol = nColScale / scale;

fxArr = [0:1:nCol-1]/nCol;
fyArr = [0:1:mRow-1]/mRow;

[fxMat, fyMat] = meshgrid(fxArr, fyArr);           % generate coordinates in Fourier domain (not neccessary)
fxMat = fftshift(fxMat);
fyMat = fftshift(fyMat);

OrderMat = getOrderMat(mRow, nCol, SamplingPath);                              % generate sampling path in Fourier domain
[nCoeft,tmp] = size(OrderMat);
nCoeft = round(nCoeft * SpectralCoverage);

InitPhaseArr = getInitPhaseArr(nStepPS, Phaseshift);
IntensityMat = zeros(mRow, nCol, nStepPS);

RealFourierCoeftList = getRealFourierCoeftList(mRow, nCol);

tic;
for iCoeft = 1:nCoeft
    iRow = OrderMat(iCoeft,1);
    jCol = OrderMat(iCoeft,2);
    
    fx = fxMat(iRow,jCol);
    fy = fyMat(iRow,jCol);
    
    IsRealCoeft = existVectorInMat( [iRow jCol], RealFourierCoeftList );
    
    for iStep = 1:nStepPS;
        if IsRealCoeft == 1 && iStep > 2
            if nStepPS == 3
                IntensityMat(iRow,jCol,iStep) = IntensityMat(iRow,jCol,2);
            end
            if nStepPS == 4
                IntensityMat(iRow,jCol,iStep) = 0;
            end
            continue;
        end
        
        Pattern  = getFourierPattern( Amplitude, mRow, nCol, fx, fy, InitPhaseArr(iStep) );
        Pattern  = imresize(Pattern, scale, 'bicubic');
        Pattern = dither(Pattern);      % Floyd-steinberg dithering
        
        IntensityMat(iRow,jCol,iStep) = sum(sum( Pattern .* InputImg ));
        
    end
end

toc;

[img, spec] = getFSPIReconstruction( IntensityMat, nStepPS, Phaseshift );

figure, imshow(mat2gray(img)); title('Reconstructed Img');
figure, specshow(spec);

