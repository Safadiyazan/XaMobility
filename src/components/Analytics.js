import React, { useState, useEffect, useRef } from 'react';
import Accordion from 'react-bootstrap/Accordion';
import Form from 'react-bootstrap/Form';
import Chart from 'chart.js/auto';
import 'bootstrap/dist/css/bootstrap.min.css';
import '.././css/main.css';

function Analytics({ data }) {
  const [processedData, setProcessedData] = useState(null);
  const [selectedVariable, setSelectedVariable] = useState('TTS');
  const [selectedXVariable, setSelectedXVariable] = useState('n');
  const [selectedYVariable, setSelectedYVariable] = useState('G');
  const chartRef = useRef(null);
  const scatterChartRef = useRef(null);

  useEffect(() => {
    if (data && data.TFC && data.TFC.N) {
      let selectedValues;

      if (selectedVariable && selectedVariable.startsWith('EC')) {
        const ecData = data.TFC.EC.N;
        selectedValues = ecData[selectedVariable];
      } else {
        const tfcData = data.TFC.N;
        selectedValues = tfcData[selectedVariable];
      }
      if (selectedValues) {
        const dtS = data.SimInfo.dtM; 
        const labels = selectedValues.map((_, index) => (index + 1) * dtS); 
        const labelsWithZero = [0, ...labels];
        const valuesWithZero = [0, ...selectedValues];

        setProcessedData({
          labels: labelsWithZero,
          values: valuesWithZero,
        });
      } else {
        console.error("Selected variable data not found");
      }
    }
  }, [data, selectedVariable]);

  useEffect(() => {
    if (processedData) {
      const variableLabels = {
        TTS: 'Total Time Spent (TTS) [aircraft.s]',
        TTD: 'Total Travelled Distance (TTD) [aircraft.m]',
        EC: 'Total Energy Consumption (TEC) [aircraft.Wh]',
        Q: 'Flow [aircraft/s/m2]',
        K: 'Density [aircraft/m3]',
        V: 'Speed [m/s]',
        n: 'Accumulation [aircraft]',
        G: 'Outflow [aircraft/s]',
      };

      const chartData = {
        labels: processedData.labels,
        datasets: [
          {
            label: variableLabels[selectedVariable],
            data: processedData.values,
            backgroundColor: 'rgba(192,40,45, 0.2)',
            borderColor: 'rgba(192,40,45, 1)',
            borderWidth: 1,
          },
        ],
      };

      const chartConfig = {
        type: 'line',
        data: chartData,
        options: {
          scales: {
            x: {
              title: {
                display: true,
                text: 'Time [s]',
                font: {
                  family: 'Latin Modern',
                },
              },
              ticks: {
                font: {
                  family: 'Latin Modern',
                },
              },
            },
            y: {
              title: {
                display: true,
                text: variableLabels[selectedVariable] || selectedVariable,
                font: {
                  family: 'Latin Modern',
                },
              },
              ticks: {
                font: {
                  family: 'Latin Modern',
                },
              },
            },
          },
          plugins: {
            legend: {
              labels: {
                font: {
                  family: 'Latin Modern',
                },
              },
            },
          },
        },
      };

      const myChart = new Chart(chartRef.current, chartConfig);

      return () => {
        myChart.destroy();
      };
    }
  }, [processedData, selectedVariable]);

  useEffect(() => {
    if (data && data.TFC && data.TFC.N) {

      let xValues, yValues;

      if (selectedXVariable && selectedXVariable.startsWith('EC')) {
        const ecData = data.TFC.EC.N;
        xValues = ecData[selectedXVariable];
      } else {
        const tfcData = data.TFC.N;
        xValues = tfcData[selectedXVariable];
      }

      if (selectedYVariable && selectedYVariable.startsWith('EC')) {
        const ecData = data.TFC.EC.N;
        yValues = ecData[selectedYVariable];
      } else {
        const tfcData = data.TFC.N;
        yValues = tfcData[selectedYVariable];
      }

      if (xValues && yValues) {
        const scatterData = xValues.map((x, index) => ({
          x: x,
          y: yValues[index],
        }));

        const variableLabels = {
          TTS: 'Total Time Spent (TTS) [aircraft.s]',
          TTD: 'Total Travelled Distance (TTD) [aircraft.m]',
          EC: 'Total Energy Consumption (TEC) [aircraft.Wh]',
          Q: 'Flow [aircraft/s/m2]',
          K: 'Density [aircraft/m3]',
          V: 'Speed [m/s]',
          n: 'Accumulation [aircraft]',
          G: 'Outflow [aircraft/s]',
        };

        const scatterChartData = {
          datasets: [
            {
              label: `${variableLabels[selectedXVariable]} vs ${variableLabels[selectedYVariable]}`,
              data: scatterData,
              backgroundColor: 'rgba(7,103,144, 0.2)',
              borderColor: 'rgba(7,103,144, 1)',
              borderWidth: 1,
            },
          ],
        };

        const scatterChartConfig = {
          type: 'scatter',
          data: scatterChartData,
          options: {
            scales: {
              x: {
                title: {
                  display: true,
                  text: variableLabels[selectedXVariable] || selectedXVariable,
                  font: {
                    family: 'Latin Modern',
                  },
                },
                ticks: {
                  font: {
                    family: 'Latin Modern',
                  },
                },
              },
              y: {
                title: {
                  display: true,
                  text: variableLabels[selectedYVariable] || selectedYVariable,
                  font: {
                    family: 'Latin Modern',
                  },
                },
                ticks: {
                  font: {
                    family: 'Latin Modern',
                  },
                },
              },
            },
            plugins: {
              legend: {
                labels: {
                  font: {
                    family: 'Latin Modern',
                  },
                },
              },
            },
          },
        };

        const scatterChart = new Chart(scatterChartRef.current, scatterChartConfig);

        return () => {
          scatterChart.destroy();
        };
      } else {
        console.error("Selected variable data not found");
      }
    }
  }, [data, selectedXVariable, selectedYVariable]);

  const handleVariableChange = (event) => {
    setSelectedVariable(event.target.value);
  };

  const handleXVariableChange = (event) => {
    setSelectedXVariable(event.target.value);
  };

  const handleYVariableChange = (event) => {
    setSelectedYVariable(event.target.value);
  };

  return (
    <div>
      <hr />
      <Accordion defaultActiveKey="0">
        <Accordion.Header>
          <center>
            <b>
              <h4>Analytics</h4>
            </b>
          </center>
        </Accordion.Header>
        <Accordion.Body>
          <Accordion defaultActiveKey="0">
            <Accordion.Item eventKey="1">
              <Accordion.Header>Time series</Accordion.Header>
              <Accordion.Body>
                <Form.Group>
                  <Form.Label>Select Variable:</Form.Label>
                  <Form.Control
                    as="select"
                    value={selectedVariable}
                    onChange={handleVariableChange}
                  >
                    <option value="TTS">Total Time Spent (TTS)</option>
                    <option value="TTD">Total Travelled Distance (TTD)</option>
                    <option value="EC">Total Energy Consumption (TEC)</option>
                    <option value="Q">Flow (Q)</option>
                    <option value="K">Density (K)</option>
                    <option value="V">Speed (V)</option>
                    <option value="n">Accumulation (n)</option>
                    <option value="G">Outflow (G)</option>
                  </Form.Control>
                </Form.Group>
                <div>
                  {processedData ? (
                    <canvas ref={chartRef} id="myChart"></canvas>
                  ) : (
                    <div>Loading chart data...</div>
                  )}
                </div>
              </Accordion.Body>
            </Accordion.Item>
            <Accordion.Item eventKey="2">
              <Accordion.Header>Scatter plot</Accordion.Header>
              <Accordion.Body>
                <Form.Group>
                  <Form.Label>Select X Variable:</Form.Label>
                  <Form.Control
                    as="select"
                    value={selectedXVariable}
                    onChange={handleXVariableChange}
                  >
                    <option value="TTS">Total Time Spent (TTS)</option>
                    <option value="TTD">Total Travelled Distance (TTD)</option>
                    <option value="EC">Total Energy Consumption (TEC)</option>
                    <option value="Q">Flow (Q)</option>
                    <option value="K">Density (K)</option>
                    <option value="V">Speed (V)</option>
                    <option value="n">Accumulation (n)</option>
                    <option value="G">Outflow (G)</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group>
                  <Form.Label>Select Y Variable:</Form.Label>
                  <Form.Control
                    as="select"
                    value={selectedYVariable}
                    onChange={handleYVariableChange}
                  >
                    <option value="TTS">Total Time Spent (TTS)</option>
                    <option value="TTD">Total Travelled Distance (TTD)</option>
                    <option value="EC">Total Energy Consumption (TEC)</option>
                    <option value="Q">Flow (Q)</option>
                    <option value="K">Density (K)</option>
                    <option value="V">Speed (V)</option>
                    <option value="n">Accumulation (n)</option>
                    <option value="G">Outflow (G)</option>
                  </Form.Control>
                </Form.Group>
                <div>
                  <canvas ref={scatterChartRef} id="scatterChart"></canvas>
                </div>
              </Accordion.Body>
            </Accordion.Item>
          </Accordion>
        </Accordion.Body>
      </Accordion>
      <hr />
    </div>
  );
}

export default Analytics;
