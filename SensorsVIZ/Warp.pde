/**
 * Generate a shape object that can be distorted using a bunch of control points to fit an irregular
 * 3D surface where a canvas is projected using a beamer
 * @author    Marc Vilella
 * @version   0.3
 */
public class WarpSurface {

  private PVector[][] points;
  private int cols, rows;
  private PVector controlPoint;

  private boolean calibrateMode;

  /**
   * Construct a warp surface containing a grid of control points. By default thw surface
   * is placed at the center of sketch
   * @param parent    the sketch PApplet
   * @param width     the surface width
   * @param height    the surface height
   * @param cols      the number of horizontal control points
   * @param rows      the number of vertical control points
   */
  public WarpSurface(PApplet parent, float width, float height, int cols, int rows) {

    parent.registerMethod("mouseEvent", this);
    parent.registerMethod("keyEvent", this);

    this.cols = cols;
    this.rows = rows;

    float initX = parent.width / 2 - width / 2;
    float initY = parent.height / 2 - height / 2;
    float dX = width / (cols - 1);
    float dY = height / (rows - 1);

    points = new PVector[rows][cols];
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        points[y][x] = new PVector(initX + x * dX, initY + y * dY);
      }
    }
  }


  /**
   * Draw the canvas in surface, warping it as a texture. While in
   * calibration mode the control points can be moved with a mouse drag
   * @param canvas    the canvas 
   */
  public void draw(Canvas canvas) {

    float dX = canvas.width / (cols - 1);
    float dY = canvas.height / (rows - 1);

    for (int y = 0; y < rows -1; y++) {
      beginShape(TRIANGLE_STRIP);
      texture(canvas);
      for (int x = 0; x < cols; x++) {

        if (calibrateMode) {
          stroke(#FF0000);
          strokeWeight(0.5);
        } else noStroke();

        vertex(points[y][x].x, points[y][x].y, canvas.width - x * dX, canvas.height - y * dY);
        vertex(points[y+1][x].x, points[y+1][x].y, canvas.width - x * dX, canvas.height - (y+1) * dY);
      }
      endShape();
    }
  }


  /**
   * Toggle callibration mode of surface, allowing to drag and move control points
   */
  public void toggleCalibration() {
    calibrateMode = !calibrateMode;
  }


  /**
   * Return whether the surface is in calibration mode
   * @return    true if surface is in calibration mode, false otherwise
   */
  public boolean isCalibrating() {
    return calibrateMode;
  }


  /**
   * Load the position of control points from an XML file, by default "warp.xml"
   */
  public void loadConfig() {
    XML settings = loadXML(sketchPath("warp.xml"));
    XML size = settings.getChild("size");
    rows = size.getInt("rows");
    cols = size.getInt("cols");
    XML[] xmlPoints = settings.getChild("points").getChildren("point");
    points = new PVector[rows][cols];
    for (int i = 0; i < xmlPoints.length; i++) {
      int x = i % cols;
      int y = i / cols;
      points[y][x] = new PVector(xmlPoints[i].getFloat("x"), xmlPoints[i].getFloat("y"));
    }
  }


  /**
   * Save the position of control points into an XML file, by default "warp.xml"
   */
  public void saveConfig() {
    XML settings = new XML("settings");
    XML size = settings.addChild("size");
    size.setInt("cols", cols);
    size.setInt("rows", rows);
    XML xmlPoints = settings.addChild("points");
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        XML point = xmlPoints.addChild("point");
        point.setFloat("x", points[y][x].x);
        point.setFloat("y", points[y][x].y);
      }
    }
    saveXML(settings, "warp.xml");
    println("Warp configuration saved");
  }


  /**
   * Mouse event handler to perform control point dragging
   * @param e    the mouse event
   */
  public void mouseEvent(MouseEvent e) {
    switch(e.getAction()) {

    case MouseEvent.PRESS:
      if (calibrateMode) {
        controlPoint = null;
        for (int y = 0; y < rows; y++) {
          for (int x = 0; x < cols; x++) {
            PVector mousePos = new PVector(mouseX, mouseY);
            if (mousePos.dist(points[y][x]) < 10) {
              controlPoint = points[y][x];
              break;
            }
          }
        }
      }
      break;

    case MouseEvent.DRAG:
      if (calibrateMode && controlPoint != null) {
        controlPoint.x = mouseX;
        controlPoint.y = mouseY;
      }
      break;
    }
  }


  /**
   * Key event handler to perform calibration movement of the surface
   * @param e    the key event
   */
  public void keyEvent(KeyEvent e) {
    if (calibrateMode) {
      switch(e.getAction()) {
      case KeyEvent.PRESS:
        switch(e.getKey()) {
        case 'l':
          loadConfig();
          break;
        case 's':
          saveConfig();
        }
        switch(e.getKeyCode()) {
        case UP:
          this.move(0, -5);
          break;
        case DOWN:
          this.move(0, 5);
          break;
        case LEFT:
          this.move(-5, 0);
          break;
        case RIGHT:
          this.move(5, 0);
          break;
        }
        break;
      }
    }
  }


  /**
   * Move surface
   * @param dX    Horizontal displacement
   * @param dY    Vertical displacement
   */
  protected void move(int dX, int dY) {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        points[r][c].x += dX;
        points[r][c].y += dY;
      }
    }
  }
}
