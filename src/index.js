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
import About from './components/About';
import Footer from './components/Footer';
import Login from './components/Login';
import './css/main.css'; // Ensure this import is here

// =======================================================================================
// Cesium Viewer Setting =================================================================
import { IonResource, ClockStep, ClockRange, HeadingPitchRoll, VelocityOrientationProperty, PathGraphics, DistanceDisplayCondition, CallbackProperty, TimeInterval, TimeIntervalCollection, SampledPositionProperty, JulianDate, Cartographic, Sun, ShadowMode, Color, Ellipsoid, Matrix4, Transforms, Cesium3DTileset, Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import "cesium/Build/Cesium/Widgets/widgets.css";
Ion.defaultAccessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI0NmYxNjYzNi1kNmQ4LTQzMGEtOGU4Ni1mN2U5OTVlYzc5MmUiLCJpZCI6MTE4MzUyLCJpYXQiOjE2ODM5MDk0OTN9.HrVvhv9eAppSV01COmDor3CGuppPz5iEEtNFeF_wzp8';
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
// const tileset = viewer.scene.primitives.add(
//   await Cesium.Cesium3DTileset.fromIonAssetId(75343),
// );


// =======================================================================================
// App UI ================================================================================
function App() {
  
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [username, setUsername] = useState('');
  // useEffect(() => {
  //   const storedUsername = localStorage.getItem('username');
  //   if (storedUsername) {
  //     setUsername(storedUsername);
  //     setIsAuthenticated(true);
  //   }
  // }, []);

  const handleLogin = async (username) => {
    try {
      setUsername(username);
      setIsAuthenticated(true);
      localStorage.setItem('username', username);
      console.log('Login successful');
    } catch (error) {
      console.error('Error during login:', error);
    }
  };

  const handleLogout = async () => {
    try {
      const response = await fetch('/api/logout', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // Include credentials for server-side session handling
      });

      if (response.ok) {
        setIsAuthenticated(false);
        setUsername('');
        localStorage.removeItem('username');
        console.log('Logout successful');
      } else {
        console.error('Logout failed');
      }
    } catch (error) {
      console.error('Error during logout:', error);
    }
  };

  return (
    <div>
      <Router>
        <div className="d-flex flex-column min-vh-100">
          <Header
            isAuthenticated={isAuthenticated}
            onLoginButtonClick={() => console.log('Navigate to login page')}
            username={username}
            onLogout={handleLogout}
          />
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" />} />
            <Route
              path="/dashboard"
              element={isAuthenticated ? <Dashboard /> : <Navigate to="/login" />}
            />
            <Route path="/login" element={<Login onLogin={handleLogin} />} />
            <Route path="/about" element={<About />} />
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