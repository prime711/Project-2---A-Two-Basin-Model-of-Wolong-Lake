// =======================================================================================
// The following codes are used for the code editor in Google Earth Engine (GEE) platform
// =======================================================================================

// Wolong Lake: Sentinel-2 water mask, lake-only north/south split,
// area shares, and Figure 1c export.  One script, one mask.
// =====================================================================

// ---------------------------------------------------------------
// 1. Settings
// ---------------------------------------------------------------
var center = ee.Geometry.Point([123.2796, 42.7472]);   // lake centre
var lat    = 42.7472;                                  // north/south split latitude
var region = center.buffer(8000);                      // search area (8 km radius)
var START = '2023-06-01', END = '2023-09-30';
var CLOUD_MAX = 10;                                    // scene-level cloud % limit
var NDWI_THRESHOLD = 0.1;
var OPEN_RADIUS = 3;                                   // pixels (30 m): removes water features narrower than ~60 m

Map.setOptions('SATELLITE');
Map.centerObject(center, 12);

// ---------------------------------------------------------------
// 2. Sentinel-2 Level-2A median composite
// ---------------------------------------------------------------
var col = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(region)
  .filterDate(START, END)
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', CLOUD_MAX));
print('Number of scenes in composite (n):', col.size());
var s2  = col.median();
var rgb = s2.visualize({bands: ['B4', 'B3', 'B2'], min: 0, max: 3000});

// ---------------------------------------------------------------
// 3. NDWI water mask (McFeeters, 1996)
// ---------------------------------------------------------------
var ndwi  = s2.normalizedDifference(['B3', 'B8']).rename('NDWI');
var water = ndwi.gt(NDWI_THRESHOLD).selfMask();        // 1 = water, masked elsewhere
Map.addLayer(water.clip(region), {palette: ['blue']}, 'All water (check)', false);

// ---------------------------------------------------------------
// 4. Find the lake automatically = largest connected water body
//    after removing thin channels (canals, rivers) by morphological opening
// ---------------------------------------------------------------
var kernel = ee.Kernel.circle({radius: OPEN_RADIUS, units: 'pixels'});
var opened = water.unmask(0)
  .focal_min({kernel: kernel, iterations: 1})
  .focal_max({kernel: kernel, iterations: 1})
  .selfMask()
  .clip(region);

var vectors = opened.reduceToVectors({
  geometry: region,
  scale: 10,
  geometryType: 'polygon',
  eightConnected: true,
  labelProperty: 'water',
  maxPixels: 1e9
}).map(function (f) {
  return f.set('area_m2', f.geometry().area(1));
});

var lakeFeature = ee.Feature(vectors.sort('area_m2', false).first());
var lakePolygon = lakeFeature.geometry();
// To use your own hand-drawn polygon instead, uncomment the next line:
// var lakePolygon = geometry;

Map.addLayer(ee.FeatureCollection([ee.Feature(lakePolygon)])
  .style({color: 'white', fillColor: '00000000', width: 2}), {}, 'Lake polygon (CHECK)');

// ---------------------------------------------------------------
// 5. Lake-only water and north / south split
// ---------------------------------------------------------------
var lakeWater  = water.clip(lakePolygon);
var latImg     = ee.Image.pixelLonLat().select('latitude');
var northWater = lakeWater.updateMask(latImg.gte(lat));
var southWater = lakeWater.updateMask(latImg.lt(lat));

// ---------------------------------------------------------------
// 6. Water-surface area and shares
// ---------------------------------------------------------------
var lakeBox = lakePolygon.bounds();
function waterArea(img) {
  return ee.Number(ee.Image.pixelArea().updateMask(img).reduceRegion({
    reducer: ee.Reducer.sum(),
    geometry: lakeBox,
    scale: 10,
    maxPixels: 1e9
  }).get('area'));
}
var aN = waterArea(northWater);
var aS = waterArea(southWater);
var aT = aN.add(aS);

//Note: tiff format when exported
print('North water area (km2):', aN.divide(1e6));
print('South water area (km2):', aS.divide(1e6));
print('Total lake water area (km2):', aT.divide(1e6));
print('North share (%):', aN.divide(aT).multiply(100));
print('South share (%):', aS.divide(aT).multiply(100));

// ---------------------------------------------------------------
// 7. Figure 1c layers and export (same masks as the area calculation)
// ---------------------------------------------------------------
var northVis   = northWater.visualize({palette: ['red']});
var southVis   = southWater.visualize({palette: ['yellow']});
var finalImage = rgb.blend(southVis).blend(northVis);
Map.addLayer(finalImage, {}, 'Final Figure');

Export.image.toDrive({
  image: finalImage,
  description: 'WolongLake_NorthSouth_FinalFigure',
  scale: 10,
  region: lakeBox.buffer(1500).bounds(),               // tight frame so the lake fills the panel
  maxPixels: 1e9
});


//export the images as pdf format

Export.image.toDrive({
  image: rgb,
  description: 'WolongLake_TrueColor_PanelB',
  scale: 10,
  region: lakeBox.buffer(1500).bounds(),
  maxPixels: 1e9
});

var frame = lakeBox.buffer(1500).bounds();   // same frame as your exports

print('Panel (c) PNG link:', finalImage.getThumbURL({
  region: frame, dimensions: 2000, format: 'png'}));
print('Panel (b) PNG link:', rgb.getThumbURL({
  region: frame, dimensions: 2000, format: 'png'}));
