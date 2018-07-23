%% 2013/10/28
% Rev 1: 2015/1/22 by Charles Cheung
% Rev 2: 2016/6/23 by Charles Cheung

%% simulating single-pixel imaging with phase-shifting sinusoid illumination
close all
clear all
clc

%% Parameters
nStepPS = 3;
Phaseshift = 120;
scale = 2;
amp = 1;

% Get input image
[imgFile pathname] = uigetfile({'*.bmp;*.jpg;*.tif;*.png;*.gif'','...
    'All Image Files';'*.*','All Files'});
InputImg = im2double(imread([pathname '\' imgFile]));

figure,imshow(InputImg);title('Input image'); axis image;

[mRowScale, nColScale] = size(InputImg);

mRow = mRowScale / scale;
nCol = nColScale / scale;

% mRow ~= nCol is not allowed
if mRow ~= nCol
    error('Input image should be square!');
end

% Get frequency axis
nPixel = mRow;

[fxMat, fyMat] = meshgrid(linspace(0,(nPixel-1)/nPixel,nPixel),...
    linspace(0,(nPixel-1)/nPixel,nPixel)) ;
fxMat = fftshift(fxMat);
fyMat = fftshift(fyMat);

% Get the order matrix
OrderMat = getOrderMat(nPixel, nPixel, 'Spiral');

% Get the path matrix
[nFreq,tmp] = size(OrderMat);

InitPhaseArr = getInitPhaseArr (nStepPS, Phaseshift);

IntensityMat = zeros(mRow, nCol, nStepPS);

tic;
for iFreq = 1:nFreq
    iRow = OrderMat(iFreq,1);
    jCol = OrderMat(iFreq,2);
    
    fx = fxMat(iRow, jCol);
    fy = fyMat(iRow, jCol);
        
    for iStep = 1:nStepPS;
        fringe = getFringe( amp, nPixel, fx, fy, InitPhaseArr(iStep));
        fringe = imresize(fringe, scale, 'bicubic');
        
%          level = graythresh(fringe); fringe = im2bw(fringe,level); % Global image threshold using Otsu's method
%        fringe = dither(fringe);      % Floyd-steinberg dithering
%        fringe = im2bw(fringe, 0.5);  % Fixed threshold dithering
       fringe = orderedThreshold(uint8(fringe*255), 4); % Bayer's threshold dithering 使用时要确保输入图像为0~255
%        fringe = randomThreshold(uint8(fringe*255), 5); % Random threshold dithering

        IntensityMat(iRow,jCol,iStep) = sum(sum( fringe .* InputImg ));
    end
end

toc;

[img, spec] = getFSPIReconstruction( IntensityMat, nStepPS, Phaseshift );

% figure, imagesc(img); colormap gray; title('Reconstructed Img');
figure, imshow(mat2gray(img)); title('Reconstructed Img');
figure, specshow(spec);

%% Saving results
