function Irange = extract_intensity(imagePath)

% Convert to grayscale if necessary
originalImage = imread(imagePath);
[~, ~, numberOfColorChannels] = size(originalImage);
if numberOfColorChannels > 1
    fprintf('Original image file has %d color channels. Converting to grayscale...\n', numberOfColorChannels);
    grayImage = rgb2gray(originalImage);
else
    grayImage = originalImage;
end

% Display the image for line drawing
figureHandle = figure;
imshow(grayImage,'InitialMagnification', 'fit');
title('Draw a line to define intensity range (click start and end points)');

% Allow the user to draw a line interactively
roi = drawline('Color', 'r');

% Wait for the user to confirm the line drawing
wait(roi);

% Get the coordinates of the line
line_xs = [roi.Position(1, 1), roi.Position(2, 1)];
line_ys = [roi.Position(1, 2), roi.Position(2, 2)];

% Extract pixel values along the line
pixvals = improfile(grayImage, line_xs, line_ys);

% Plot the intensity profile
figure;
plot(1:length(pixvals), pixvals,'k');
axis tight;
title('Pixel Values Along the Line');
ylabel('Pixel Greyscale Values');
xlabel('Relative Position from Line Start (0) to Line End');

% Prompt for intensity range input
userPrompt = {'Enter minimum intensity:', 'Enter maximum intensity:'};
dialogTitle = 'Specify Intensity Range';
def = {'0', '100'};
answer = inputdlg(userPrompt, dialogTitle, 1, def);
if isempty(answer)
    close(figureHandle);
    return;
end

% Parse the user's input
intensity.min = str2double(answer{1});
intensity.max = str2double(answer{2});

% Close the figure after the user input
close(figureHandle);

% Return the intensity range
Irange = [intensity.min, intensity.max];

end

