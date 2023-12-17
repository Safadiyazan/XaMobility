import React, { useState, useEffect } from 'react';
import Accordion from 'react-bootstrap/Accordion';
import Form from 'react-bootstrap/Form';
import { Button } from 'react-bootstrap';
import * as d3 from 'd3';

function Analytics() {
  const [data, setData] = useState(/* Your data goes here */);
  const [xAxisOption, setXAxisOption] = useState('Time');
  const [yAxisOption, setYAxisOption] = useState('Flow');

  useEffect(() => {
    // Fetch or set your data here

    // Example data format:
     const data = [
       { Time: 1, Flow: 10, Density: 20, Speed: 30 },
       { Time: 2, Flow: 15, Density: 25, Speed: 35 },
       // Add more data points as needed
     ];

    // Set the data
    setData(data);

    // Call the function to render the D3 chart
    renderTimeSeriesChart(data, xAxisOption, yAxisOption);
  }, [xAxisOption, yAxisOption]);

  const renderTimeSeriesChart = (data, xAxisOption, yAxisOption) => {
    // Clear previous chart
    d3.select('#time-series-chart').selectAll('*').remove();
  
    // Set chart dimensions
    const margin = { top: 20, right: 30, bottom: 40, left: 50 };
    const width = 600 - margin.left - margin.right;
    const height = 400 - margin.top - margin.bottom;
  
    // Create SVG container
    const svg = d3
      .select('#time-series-chart')
      .append('svg')
      .attr('width', width + margin.left + margin.right)
      .attr('height', height + margin.top + margin.bottom)
      .append('g')
      .attr('transform', `translate(${margin.left},${margin.top})`);
  
    // Access data based on selected options
    const xData = data.map((d) => d[xAxisOption]);
    const yData = data.map((d) => d[yAxisOption]);
  
    // Set scales
    const xScale = d3.scaleLinear().domain([d3.min(xData), d3.max(xData)]).range([0, width]);
    const yScale = d3.scaleLinear().domain([d3.min(yData), d3.max(yData)]).range([height, 0]);
  
    // Create line function
    const line = d3
      .line()
      .x((d) => xScale(d[xAxisOption]))
      .y((d) => yScale(d[yAxisOption]));
  
    // Append line to SVG
    svg
      .append('path')
      .datum(data)
      .attr('fill', 'none')
      .attr('stroke', 'steelblue')
      .attr('stroke-width', 2)
      .attr('d', line);
  
    // Add X-axis
    svg
      .append('g')
      .attr('transform', `translate(0,${height})`)
      .call(d3.axisBottom(xScale).ticks(5))
      .append('text')
      .attr('x', width / 2)
      .attr('y', margin.bottom - 10)
      .attr('dy', '1em')
      .style('text-anchor', 'middle')
      .text(xAxisOption);
  
    // Add Y-axis
    svg
      .append('g')
      .call(d3.axisLeft(yScale).ticks(5))
      .append('text')
      .attr('transform', 'rotate(-90)')
      .attr('y', -margin.left)
      .attr('x', -height / 2)
      .attr('dy', '1em')
      .style('text-anchor', 'middle')
      .text(yAxisOption);
  };
  return (
    <div>
      <hr />
      <Accordion defaultActiveKey="0">
        <Accordion.Item eventKey="1">
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
                    <Form.Label>X-Axis:</Form.Label>
                    <Form.Control as="select" value={xAxisOption} onChange={(e) => setXAxisOption(e.target.value)}>
                      <option value="Time">Time</option>
                      {/* Add other x-axis options as needed */}
                    </Form.Control>
                  </Form.Group>
                  <Form.Group>
                    <Form.Label>Y-Axis:</Form.Label>
                    <Form.Control as="select" value={yAxisOption} onChange={(e) => setYAxisOption(e.target.value)}>
                      <option value="Flow">Flow</option>
                      <option value="Density">Density</option>
                      <option value="Speed">Speed</option>
                      {/* Add other y-axis options as needed */}
                    </Form.Control>
                  </Form.Group>
                  <div className="text-center">
                    <Button variant="primary" onClick={() => renderTimeSeriesChart(data, xAxisOption, yAxisOption)}>
                      Update Chart
                    </Button>
                  </div>
                  <div id="time-series-chart" className="mt-3"></div>
                </Accordion.Body>
              </Accordion.Item>
            </Accordion>
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
      <hr />
    </div>
  );
}

export default Analytics;
