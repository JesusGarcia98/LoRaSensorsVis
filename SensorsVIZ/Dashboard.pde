/**
 * Dashboard - Displays the most recently collected data of a GPSTempHum object
 * @author      Jesús García
 * @version     0.1
 */
public class DashboardGPSTempHum {
  private ArrayList<GPSTempHum> SENSORS = new ArrayList<GPSTempHum>();
  private PGraphics CANVASTEMP;
  private PGraphics CANVASHUM;
  private PGraphics CANVASADDRSS;


  /**
   * Creates a DashboardGPSTempHum object
   * @param sensors  Array of Sensor objects whose values will be shown  
   */
  public DashboardGPSTempHum(ArrayList<Sensor> sensors) {
    CANVASTEMP = createGraphics(420, 160);
    CANVASHUM = createGraphics(420, 160);
    CANVASADDRSS = createGraphics(560, 160);
    load(sensors);
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


  public void draw(PGraphics canvas, PFont font) {
    for (GPSTempHum sensor : SENSORS) {
      sensor.drawDashboard(canvas, CANVASTEMP, CANVASHUM, CANVASADDRSS, font);
    }
  }
}
