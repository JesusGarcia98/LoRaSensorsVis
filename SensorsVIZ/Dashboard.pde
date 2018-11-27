/**
 * Dashboard - Displays the most recently collected data of a Sensor object
 * @author      Jesús García
 * @version     0.1
 */
public class Dashboard {
  private ArrayList<GPSTempHum> SENSORS = new ArrayList<GPSTempHum>();
  private GPSTempHum SELECTED;
  private PGraphics CANVASTEMP;
  private PGraphics CANVASHUM;
  private PGraphics CANVASADRSS;


  /**
   * Creates a Dashboard object
   * @param sensors  Array of Sensor objects whose values will be shown  
   */
  public Dashboard(ArrayList<Sensor> sensors) {
    CANVASTEMP = createGraphics(420, 160);
    CANVASHUM = createGraphics(420, 160);
    CANVASADRSS = createGraphics(560, 160);
    load(sensors);
    select(0, true);
  }


  /**
   * Stores the instances of GPSTempHum from a Sensor array in an internal array
   * @param sensors  Array of Sensor instances
   */
  private void load(ArrayList<Sensor> sensors) {
    for (Sensor sensor : sensors) {
      if (sensor instanceof GPSTempHum) {
        GPSTempHum s = (GPSTempHum) sensor;
        SENSORS.add(s);
      }
    }
  }


  /**
   * Selects the GPSTempHum object whose values will be displayed
   * @param i          Index of the GPSTempHum object
   * @param selected   New value for the selected attribute of the GPSTempHum object
   */
  private void select(int i, boolean selected) {
    SELECTED = SENSORS.get(i);
    SELECTED.setSelected(selected);
  }


  public void draw(PGraphics canvas, PFont font) {
    CANVASTEMP.beginDraw();
    SELECTED.tempDashboard(CANVASTEMP, font);
    CANVASTEMP.endDraw();
    canvas.image(CANVASTEMP, 0, 0);

    CANVASHUM.beginDraw();
    SELECTED.humDashboard(CANVASHUM, font);
    CANVASHUM.endDraw();
    canvas.image(CANVASHUM, CANVASHUM.width, 0);

    CANVASADRSS.beginDraw();
    SELECTED.adrssDashboard(CANVASADRSS, font);
    CANVASADRSS.endDraw();
    canvas.image(CANVASADRSS, CANVASTEMP.width + CANVASHUM.width, 0);
  }


  /**
   * Navigates through the stored GPSTempHum objects to show their associated values
   * @param e     KeyEvent
   * @case RIGHT  Navigate from left to right
   * @case LEFT   Navigate from right to left
   */
  public void keyEvent(KeyEvent e) {
    switch(e.getKeyCode()) {
    case RIGHT:
      int i = SENSORS.indexOf(SELECTED);
      if (i < SENSORS.size() - 1) {
        select(i, false);
        i++;
        select(i, true);
      } else {
        select(i, false);
        select(0, true);
      }
      break;

    case LEFT:
      int j = SENSORS.indexOf(SELECTED);
      if (j > 0) {
        select(j, false);
        j--;
        select(j, true);
      } else {
        select(j, false);
        select(SENSORS.size()-1, true);
      }
      break;
    }
  }
}
