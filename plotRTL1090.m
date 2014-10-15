%% PlotRTL1090
%  3D visualization of air traffic through RTL-SDR (dump1090) and MATLAB
%  Copyright (C) 2014  Jorge Garcia Tiscar
% 
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation; either version 3 of the License, or
%  (at your option) any later version (see LICENSE).

%% Initialize
clear all
if exist('coords.mat','file')
    load coords
else
    lat = []; % latitude
    lon = []; % longitude 
    alt = []; % altitude
    spd = []; % speed
    flg = {}; % flight
    tim = []; % time
end

%% Acquisition loop
while true % adjust duration here or stop with Ctrl+C

    % Get data from server
    data   = urlread('http://urlofthedump1090server:8080/data.json');
    planes = fromjson(data); % https://github.com/christianpanton/matlab-json
    
    % Parse data
    N   = length(planes);
    val = 0;
    for i = 1:length(planes)
        if planes{i}.validposition
            val = val + 1;
            lat = [lat planes{i}.lat]; %#ok<*AGROW,*SAGROW>
            lon = [lon planes{i}.lon];
            alt = [alt planes{i}.altitude];
            spd = [spd planes{i}.speed];
            tim = [tim now];
            flg{length(lat)} = planes{i}.flight;
        end
    end
    disp([num2str(N) ' planes detected with ' num2str(val) ' valid coords'])
    
    % Save and continue
    save('coords.mat','lat','lon','alt','spd','flg','tim')
    pause(1)
end

%---------------------------------------------------- After stopping the loop execute the following:

%% Render the recorded data
% Prepare figure
load   coords %#ok<*UNRCH>
close  all
opengl software % Hardware OpenGL rendering is unreliable for exporting images
figure('Renderer','opengl',...
       'DefaultTextFontName', 'Miryad Pro', ...
       'DefaultTextFontSize', 10,...
       'DefaultTextHorizontalAlignment', 'right')

% Settings
centerLoc = [39.489233,-0.478026]; % LEVC
lineColor = [0.7,0.7,0.7];
vertiExag = 5; % vertical exaggeration
markSize  = 21;
maxRadius = 200e3; % bullseye max radius (m)
hold on

% Prepare UTM scenario
mstruct      = defaultm('utm');
mstruct.zone = utmzone(centerLoc(1),centerLoc(2));
mstruct      = defaultm(mstruct);

% Plot land contours
% SHPs from Natural Earth: http://www.naturalearthdata.com/downloads/10m-cultural-vectors/
SHPdir    = '.\SHPs\';
% Change 'es' for the ISO_A2 code of your country
% For all countries delete selector or input non-existent field (ISO_A2 => foo)
countries = shaperead([SHPdir '10m_cultural\ne_10m_admin_0_countries.shp'],...
            'Selector',{@(x) strcmpi(x,'es'),'ISO_A2'},'UseGeoCoords', true);
% Change 'ES.VC' for the provinces/states of your preference or use a RegExp
% for all provinces: @(x) strcmpi(x,'ES.VC') => @(x) ~isempty(regexpi(x,'^ES.*$'))
provinces = shaperead([SHPdir '10m_cultural\ne_10m_admin_1_states_provinces.shp'],...
            'Selector',{@(x) strcmpi(x,'ES.VC'),'region_cod'},'UseGeoCoords', true);
[x,y]     = mfwdtran(mstruct,[countries.Lat provinces.Lat],[countries.Lon provinces.Lon]);
[xc,yc]   = mfwdtran(mstruct,centerLoc(1),centerLoc(2));
plot(x,y,'-k')

% Plot bullseye
t = linspace(0,2*pi);
for i = 0:50e3:maxRadius
    plot(xc+i.*cos(t),yc+i.*sin(t),'-','color',lineColor)
    if i>0
        text(xc+i-15e3, yc-15e3, [num2str(i/1e3) 'km'],'color',lineColor,'HorizontalAlignment','center');
    end
end

% Plot lines
plot([xc xc],[yc-i-10e3 yc+i+10e3],'-','color',lineColor)
plot([xc-i-10e3 xc+i+10e3],[yc yc],'-','color',lineColor)

% Plot traces
filter    = alt < 150000; % You can filter per altitude (feet), speed, etc.
                          % To filter per airline use a cell function:
                          % For Ryanair: filter = cellfun(@(x) ~isempty(regexpi(x,'^RYR.*$')),flg);
color     = alt; % Color by altitude or by speed, squawk... 
[x,y]     = mfwdtran(mstruct,lat(filter),lon(filter));
scatter3(x(filter),y(filter),vertiExag.*alt(filter).*0.3048,markSize,color(filter),'Marker','.')

% Some more figure settings
axis equal
extra     = 40e3; % some extra space around the bullseye
axis([xc-i-extra xc+i+extra yc-i-extra yc+i+extra])
set(gcf, 'Color', 'white');
axis off

% Prepare 3D view
pos       = [0, 0, 856, floor(482/0.8)]; % This gives a 854 x 480 mp4/gif whith the selected cropping
set(gcf, 'Position', pos);
axis vis3d
view(-7,26) % Some fiddling required!
camzoom(1.65) % Same here!
set(gca, 'LooseInset', [0,0,0,0]);

% Prepare animation
filename  = 'plot1090_3D';
duration  = 7; % Adjust at will!
frameRate = 25; 

% Prepare MP4
try
    myVideo = VideoWriter(filename,'MPEG-4');
catch error % Video didn't close!
    close(myVideo);
    myVideo = VideoWriter(filename,'MPEG-4');
end
myVideo.FrameRate = frameRate;  
myVideo.Quality   = 100; % High quality! 
open(myVideo)

% Rotation loop
frames = frameRate*duration; 
for i = 1:frames

  % Move camera
  camorbit(360/frames,0,'data',[0 0 1])
  frame = getframe(gcf,pos-[0 0 0 round(0.2*pos(4))]); % Cropping as needed (top 20% here)
  
  % Write GIF
  im = frame2im(frame);
  [imind,cm] = rgb2ind(im,256);
  if i == 1;
      imwrite(imind,cm,[filename '.gif'],'gif','Loopcount',inf,'DelayTime',1/frameRate);
  else
      imwrite(imind,cm,[filename '.gif'],'gif','WriteMode','append','DelayTime',1/frameRate);
  end
  
  % Write MP4
  writeVideo(myVideo,frame);
end
close(myVideo);

% This is the end...
