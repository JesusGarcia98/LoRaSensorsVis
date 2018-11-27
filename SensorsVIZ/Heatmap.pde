/**
 * HEATMAP - Generate a heatmap for a group of Placeable items
 * @author        Marc Vilella
 * @modified      Jesús García
 * @credits       Philipp Seifried  http://philippseifried.com/blog/2011/09/30/generating-heatmaps-from-code/
 * @version       1.2
 */

public class Heatmap {

  private String title = "TITLE";
  private final PVector POSITION;
  private final int WIDTH, HEIGHT;

  private PImage heatmap, brush;
  private HashMap<String, PImage> gradients = new HashMap<String, PImage>(); 
  private String useGradient;

  private float maxValue = 0;
  private boolean visible = false;


  /**
   * Initiate heatmap, defining its location and size
   * @param x  Horizontal location of heatmap
   * @param y  Vertical location of heatmap
   * @param width  Width of heatmap
   * @param height  Height of heatmap
   */
  Heatmap(int x, int y, int width, int height) {
    POSITION = new PVector(x, y);
    WIDTH = width;
    HEIGHT = height;

    // Default B/W gradient
    PImage defaultGradient = createImage(255, 1, RGB);
    for (int i = 0; i < defaultGradient.pixels.length; i++) defaultGradient.pixels[i] = color(i, i, i);
    gradients.put("default", defaultGradient);
  }


  /**
   * Set a new brush from an image
   * @param imagePath  Path to brush image
   * @param brushSize  Size of brush
   */
  public void setBrush(String imagePath, int brushSize) {
    brush = loadImage(imagePath);
    brush.resize(brushSize, brushSize);
  }


  /**
   * Save a new color gradient
   * @param name  Name identifier for gradient
   * @param imagePath  Path to the gradient image
   */
  public void addGradient(String name, String imagePath) {
    File file = new File(dataPath(imagePath));
    if ( file.exists() ) gradients.put(name, loadImage(imagePath));
  }


  /**
   * Change visibility of heatmap
   */
  public void toggleVisibility() {
    visible = !visible;
  }


  /**
   * Check if heatmap is visible
   * @return true if heatmap is visible, false otherwise
   */
  public boolean isVisible() {
    return visible;
  }


  /**
   * Update heatmap with new objects. Overrides previous heatmap
   * @param title  Title for new heatmap
   * @param objects  List of (Placeable) objects to generate heatmap
   */
  public void update(String title, Sensors objects) {
    update(title, objects, "default");
  }


  /**
   * Update heatmap with new objects, using a specific gradient. Overrides previous heatmap
   * @param title  Title for new heatmap
   * @param objects  List of (Placeable) objects to generate heatmap
   * @param gradient  Name identifier of gradient
   */
  public void update(String title, Sensors sensors, String gradient) {
    maxValue = 0;
    this.title = title;
    if (visible) {
      PImage gradientMap = createImage(WIDTH, HEIGHT, ARGB);
      gradientMap.loadPixels();

      for (Sensor sensor : sensors.SENSORS) {
        if (sensor instanceof HistoricalSensor) {
          HistoricalSensor h = (HistoricalSensor) sensor;
          for (PVector pos : h.getPositions()) {
            gradientMap = addGradientPoint(gradientMap, pos.x, pos.y);
          }
        }
      }
      gradientMap.updatePixels();

      useGradient = gradient;
      PImage gradientColors = gradients.containsKey(useGradient) ? gradients.get(useGradient) : gradients.get("default"); // Prevent unexistant gradient
      heatmap = colorize(gradientMap, gradientColors);
    }
  }


  /**
   * Add point (brush) to grayscale heatmap
   * @param img  Image to add point  
   * @param x  Horizontal position of brush's center
   * @param y  Vertical position of brush's center
   * @return resulting grayscale heatmap
   */
  private PImage addGradientPoint(PImage img, float x, float y) {
    int startX = int(x - brush.width / 2);
    int startY = int(y - brush.height / 2);
    for (int pY = 0; pY < brush.height; pY++) {
      for (int pX = 0; pX < brush.width; pX++) {
        int hmX = startX + pX;
        int hmY = startY + pY;
        if ( hmX < 0 || hmY < 0 || hmX >= img.width || hmY >= img.height ) continue;
        int c = brush.pixels[pY * brush.width + pX] & 0xff;
        int i = hmY * img.width + hmX;
        if (img.pixels[i] < 0xffffff - c) {
          img.pixels[i] += c;
          if (img.pixels[i] > maxValue) maxValue = img.pixels[i];
        }
      }
    }
    return img;
  }


  /**
   * Apply gradient colors to grayscale heatmap
   * @param grayscaleMap  Grayscale heatmap
   * @param gradient  Gradient image
   * @return colored heatmap
   */
  private PImage colorize(PImage grayscaleMap, PImage gradient) {
    PImage coloredMap = createImage(WIDTH, HEIGHT, ARGB);
    for (int i = 0; i < grayscaleMap.pixels.length; i++) {
      int c = gradient.pixels[ (int) map(grayscaleMap.pixels[i], 0, maxValue, 0, gradient.pixels.length-1) ];
      coloredMap.pixels[i] = c;
    }
    return coloredMap;
  }


  /**
   * Draw heatmap and legend in screen
   * @param canvas  Canvas to draw heatmap
   * @param x  Horizontal coordinate to draw legend
   * @param y  Vertical coordinate to draw legend
   */
  public void draw(PGraphics canvas, int x, int y, int w, int h) {
    if (visible && heatmap != null) {
      canvas.pushStyle();
      canvas.blendMode(MULTIPLY);
      canvas.image(heatmap, POSITION.x, POSITION.y);
      canvas.popStyle();

      //Legend
      pushMatrix();
      translate(x, y);
      fill(#888888); 
      noStroke(); 
      textSize(20); 
      textAlign(CENTER, TOP);
      text(title, w/2, -h/2);
      textSize(18); 
      textAlign(LEFT, BOTTOM);
      text("0", 0, 1.5 * h);
      textAlign(RIGHT, BOTTOM);
      text(round(maxValue), w, 1.5 * h);
      image(gradients.get(useGradient), 0, 2, w, h);
      popMatrix();
    }
  }
}
