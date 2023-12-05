import { Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import "cesium/Build/Cesium/Widgets/widgets.css";
import "../src/css/main.css"
import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import React from 'react';
import { createRoot } from 'react-dom/client';
// import Header from './components/Header';
// import Dashboard from './components/Dashboard';
import About from './components/About';
import Footer from './components/Footer';
// import Login from './components/Login';

// // Your access token can be found at: https://cesium.com/ion/tokens.
// // This is the default access token
Ion.defaultAccessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI0NmYxNjYzNi1kNmQ4LTQzMGEtOGU4Ni1mN2U5OTVlYzc5MmUiLCJpZCI6MTE4MzUyLCJpYXQiOjE2ODM5MDk0OTN9.HrVvhv9eAppSV01COmDor3CGuppPz5iEEtNFeF_wzp8';

// Initialize the Cesium Viewer in the HTML element with the `cesiumContainer` ID.
const viewer = new Viewer('cesiumContainer', {
  terrain: Terrain.fromWorldTerrain(),
});    

// Fly the camera to San Francisco at the given longitude, latitude, and height.
viewer.camera.flyTo({
  destination: Cartesian3.fromDegrees(-122.4175, 37.655, 400),
  orientation: {
    heading: CesiumMath.toRadians(0.0),
    pitch: CesiumMath.toRadians(-15.0),
  }
});

// Add Cesium OSM Buildings, a global 3D buildings layer.
const buildingTileset = await createOsmBuildingsAsync();
viewer.scene.primitives.add(buildingTileset); 

function App() {
  return (
    <div>
      <h1>Your React App</h1>
      <About />
    </div>
  );
}

const domNodeA = document.getElementById('App');
const rootA = createRoot(domNodeA);
rootA.render(<App />);