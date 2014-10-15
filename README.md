PlotRTL1090
===========

> 3D visualization of air traffic through RTL-SDR (dump1090) and MATLAB

Requirements
---
A server running `dump1090` to record ADS-B data. If no server is available, two sample datasets are provided. Those have been used to generate the renders shown on the following section. 


Example results
---

Some sample data files are provided. The file `coords` contains a recording of air traffic around the Valencia area in Spain (LEVC). The file `coords_nl` has been supplied by a contributor of /r/RTLSDR using this code near Amsterdam-Schiphol area in The Netherlands (EHAM). Using these files some sample renderings are shown below.

* **Valencia Airport (LEVC)**: using the default options of the provided MATLAB script, the following render can be reproduced:
![Resultado](http://i.imgur.com/Iabj3iH.gif)

* **Amsterdam-Schiphol Airport (EHAM)**

```matlab
load('coords_nl');
centerLoc = [52.3147007,4.755935]; 
countries = shaperead([SHPdir 'ne_10m_admin_0_countries.shp'],'UseGeoCoords', true);
```

![Resultado](http://i.imgur.com/4FFDd68.gif)

* **Holding, approach and take off patterns (EHAM)**
```matlab
filter = alt < 6000;
```

![Resultado](http://i.imgur.com/RBs5bAo.png)

* **Airlines: Ryanair (EHAM)**
```matlab
filter = cellfun(@(x) ~isempty(regexpi(x,'^RYR.*$')),flg);
```
![Resultado](http://i.imgur.com/IcMkRXG.png)


Licensing
---
This code is licensed under GPL v3.
