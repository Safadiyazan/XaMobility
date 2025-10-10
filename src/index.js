import "../src/css/main.css"
import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom';
import { createRoot } from 'react-dom/client';
// =======================================================================================
// Import components =====================================================================
import Header from './components/Header';
import Dashboard from './components/Dashboard';
import Footer from './components/Footer';
import './css/main.css';

// =======================================================================================
// Cesium Viewer Setting =================================================================
import { IonResource, ClockStep, ClockRange, HeadingPitchRoll, VelocityOrientationProperty, PathGraphics, DistanceDisplayCondition, CallbackProperty, TimeInterval, TimeIntervalCollection, SampledPositionProperty, JulianDate, Cartographic, Sun, ShadowMode, Color, Ellipsoid, Matrix4, Transforms, Cesium3DTileset, Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import "cesium/Build/Cesium/Widgets/widgets.css";
import token from '../token.js';
Ion.defaultAccessToken = token; // Load Cesium Ion access token from external file at ./token.js
const viewer = new Viewer('cesiumContainer', {
  terrain: Terrain.fromWorldTerrain(),
  imageryProvider: false,
  baseLayerPicker: false,
  selectionIndicator: false,
});
viewer.scene.pick = () => { return undefined; };
const tileset = viewer.scene.primitives.add(
  await Cesium3DTileset.fromIonAssetId(2275207)
);


// =======================================================================================
// App UI ================================================================================
function App() {
  return (
    <div>
      <Router>
        <div className="d-flex flex-column min-vh-100">
          <Header />
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" />} />
            <Route path="/dashboard" element={<Dashboard />} />
          </Routes>
          <Footer />
        </div>
      </Router>
    </div>
  );
}
const domNodeA = document.getElementById('App');
const rootA = createRoot(domNodeA);
rootA.render(<App />);
// =======================================================================================
// Cesium Viewer Export for other .js files ==============================================
export { viewer };
// END  ==================================================================================
// =======================================================================================