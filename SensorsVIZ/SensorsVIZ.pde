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
final String bgPath = "bg/orto_small.jpg";
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

// Roadnetwork configuration
String roadnetworkPath = "roads/roads.geojson";

// MQTT configuration
String broker = "ssl://<yourRegion>.thethings.network:8883";
String user = "<appID>";
String password = "ttn-account-v2.<lotsOfCharacters>";
String topic = "<appID>/devices/<devID>/up";

// Sensors configuration
String sensorsPath = "sensors/sensors.json";

// Color gradient configuration
color mint, maxt;
boolean showGradient = true;

// Heatmap object
Heatmap heatmap;

void setup() {
  size(1400, 800, P2D);
  smooth();

  BG = loadImage(bgPath);
  simWidth = BG.width;
  simHeight = BG.height;

  surface = new WarpSurface(this, 900, 300, 10, 5);
  surface.loadConfig();

  canvas = new Canvas(this, simWidth, simHeight, bounds, roi);

  roadnetwork = new Lanes(roadnetworkPath, simWidth, simHeight, bounds);

  client = new MQTTClient(broker, user, password);
  client.connect();
  client.setCallback();
  client.subscribe(topic);

  sensors = new Sensors(sensorsPath, client, roadnetwork);

  mint = color(0, 255, 255);
  maxt = color(255, 255, 0);

  heatmap = new Heatmap(0, 0, simWidth, simHeight);
  heatmap.setBrush("hmap/brush_80x80.png", 40);
  heatmap.addGradient("neon", "hmap/neon.png");
}


void draw() {
  background(255);

  canvas.beginDraw();
  canvas.background(255);
  if (showBG) canvas.image(BG, 0, 0);
  roadnetwork.draw(canvas, 1, #c0c0c0);
  sensors.draw(canvas, 4);
  heatmap.draw(canvas, 200, 650, 1000, 50);
  canvas.endDraw();

  surface.draw(canvas);

  if (showGradient) drawGradient("Temperature range", "-10", "30", 200, 650, 1000, 50, mint, maxt);
}


void drawGradient(String title, String min, String max, int x, int y, float w, float h, color c1, color c2) {
  noFill();
  for (int i = x; i <= x+w; i++) {
    float inter = map(i, x, x+w, 0, 1);
    color c = lerpColor(c1, c2, inter);
    stroke(c);
    line(i, y, i, y+h);
  }

  // Legend
  pushMatrix();
  translate(x, y);
  fill(#888888); 
  noStroke(); 
  textSize(20); 
  textAlign(CENTER, TOP);
  text(title, w/2, -h/2);
  textSize(18); 
  textAlign(LEFT, BOTTOM);
  text(min, 0, 1.5 * h);
  textAlign(RIGHT, BOTTOM);
  text(max, w, 1.5 * h);
  popMatrix();
}


void keyPressed() {
  switch(key) {
  case 'b':
    showBG = !showBG;
    break;

  case 't':
    sensors.toggleHistoricals();
    break;

  case 'v':
    showGradient = !showGradient;
    heatmap.toggleVisibility();
    heatmap.update("Sensors paths", sensors, "neon");
    break;

  case 'w':
    surface.toggleCalibration();
    break;
  }
}
