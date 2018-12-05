// Background image
PImage BG;
boolean showBG = true;

// 3D Model projection
WarpSurface surface;

// Canvas Object
Canvas canvas;

// Roadnetwork
Lanes roadnetwork;

// MQTT client
MQTTClient client;

// Sensors facade;
Sensors sensors;

// Canvas and Surface configuration
int simWidth = 1000;
int simHeight = 847;
final String bgPath = "bg/orto.png";
final PVector[] bounds = new PVector[] {
  new PVector(42.482119, 1.489794), 
  new PVector(42.533768, 1.572122)
};
PVector[] roi = new PVector[] {
  new PVector(42.505086, 1.509961), 
  new PVector(42.517066, 1.544024), 
  new PVector(42.508161, 1.549798), 
  new PVector(42.496164, 1.515728)
};

LatLon[] ROI = new LatLon[] {
  new LatLon(42.505086, 1.509961), 
  new LatLon(42.517066, 1.544024), 
  new LatLon(42.508161, 1.549798), 
  new LatLon(42.496164, 1.515728)
};

// Roadnetwork configuration
String roadnetworkPath = "roads/roads.geojson";

// MQTT configuration
String broker = "<>://<yourRegion>.thethings.network:<port>";
String user = "<appID>";
String password = "ttn-account-v2.<lotsOfCharacters>";
String topic = "<appID>/devices/<devID>/up";

// Sensors configuration
String sensorsPath = "sensors/sensors.json";

// Color gradient configuration
WarpSurface gradSurface;
PGraphics gradCanvas;
color mint, maxt;
boolean showGradient = true;

// Heatmap object
Heatmap heatmap;

//Dashboard object
WarpSurface dashSurface;
DashboardGPSTempHum dashboard;
PGraphics dashCanvas;

//Font
PFont myFont;


void settings() {
  fullScreen(P3D, SPAN);
}


void setup() {
  smooth();

  myFont = createFont("Muli", 15);

  BG = loadImage(bgPath);
  simWidth = BG.width;
  simHeight = BG.height;

  surface = new WarpSurface(this, 900, 300, 10, 5, ROI);
  surface.loadMainConfig("warp.xml");

  dashSurface = new WarpSurface(this, 1400, 160, 4, 2, null);
  dashSurface.loadConfig("dash.xml");
  dashCanvas = createGraphics(1400, 160);

  canvas = new Canvas(this, simWidth, simHeight, bounds, roi);

  roadnetwork = new Lanes(roadnetworkPath, simWidth, simHeight, bounds);

  client = new MQTTClient(broker, user, password);
  client.connect();
  client.setCallback();
  client.subscribe(topic);

  sensors = new Sensors(sensorsPath, client, roadnetwork, surface);

  dashboard = new DashboardGPSTempHum(sensors.getSensors());

  mint = color(0, 255, 255);
  maxt = color(255, 255, 0);

  heatmap = new Heatmap(0, 0, simWidth, simHeight);
  heatmap.setBrush("hmap/brush_80x80.png", 40);
  heatmap.addGradient("neon", "hmap/neon.png");

  gradCanvas = createGraphics(200, 30);
  gradSurface = new WarpSurface(this, 200, 30, 2, 2, null);
  gradSurface.loadConfig("grad.xml");
}


void draw() {
  background(0);

  canvas.beginDraw();
  canvas.background(255);
  if (showBG) canvas.image(BG, 0, 0); 
  roadnetwork.draw(canvas, 1, #c0c0c0);
  sensors.draw(canvas, 10);
  heatmap.draw(canvas, 200, 650, 1000, 50);
  canvas.endDraw();
  surface.draw(canvas);

  dashCanvas.beginDraw();
  dashCanvas.background(0);
  dashboard.draw(dashCanvas, myFont);
  dashCanvas.endDraw();
  dashSurface.draw(dashCanvas);

  gradCanvas.beginDraw();
  gradCanvas.background(255);
  drawGradient(gradCanvas, "Temperature range", "-10", "30", 200, 30, mint, maxt);
  gradCanvas.endDraw();
  gradSurface.draw(gradCanvas);
}


void drawGradient(PGraphics canvas, String title, String min, String max, float w, float h, color c1, color c2) {
  canvas.noFill();
  canvas.textFont(myFont);
  for (int i = 0; i <= w; i++) {
    float inter = map(i, 0, w, 0, 1);
    color c = lerpColor(c1, c2, inter);
    canvas.stroke(c);
    canvas.line(i, 0, i, h);
  }

  // Legend
  canvas.pushMatrix();
  canvas.translate(0, 0);
  canvas.fill(0); 
  canvas.noStroke(); 
  canvas.textSize(10); 
  canvas.textAlign(CENTER, TOP);
  canvas.text(title, w/2, 0);
  canvas.textSize(9); 
  canvas.textAlign(LEFT, BOTTOM);
  canvas.text(min, 0, h);
  canvas.textAlign(RIGHT, BOTTOM);
  canvas.text(max, w, h);
  canvas.popMatrix();
}


void keyPressed() {
  switch(key) {
  case 'b':
    showBG = !showBG;
    break;

  case 'c':
    surface.toggleCalibration();
    break;

  case 'd':
    dashSurface.toggleCalibration();
    break;

  case 'e':
    dashSurface.saveConfig("dash.xml");
    println("Dashboard configuration saved");
    break;

  case 'f':
    gradSurface.toggleCalibration();
    break;

  case 'g':
    gradSurface.saveConfig("grad.xml");
    println("Gradient configuration saved");
    break;

  case 'h':
    sensors.toggleHistoricals();
    break;

  case 's':
    surface.saveMainConfig("warp.xml");
    break;

  case 'v':
    heatmap.toggleVisibility();
    heatmap.update("Sensors paths", sensors, "neon");
    break;
  }
}
