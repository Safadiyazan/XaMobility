import React, { useState, useEffect } from 'react';
import { IonResource, ClockStep, ClockRange, HeadingPitchRoll, VelocityOrientationProperty, PathGraphics, DistanceDisplayCondition, CallbackProperty, TimeInterval, TimeIntervalCollection, SampledPositionProperty, JulianDate, Cartographic, Sun, ShadowMode, Color, Ellipsoid, Matrix4, Transforms, Cesium3DTileset, Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import { Button } from 'react-bootstrap';
import { LoadSimulation } from '.././LoaderSimulation';
import '.././css/main.css'; // Ensure this import is here

const NetworkSetup = ({ }) => {

    const [isNetworkSetup, setNetworkSetup] = useState(false);

    useEffect(() => {
        // Executed only once after the component renders
        // const toolbar = document.getElementById('microtoolbar');
        // toolbar.style.display = isToolbarVisible ? 'block' : 'none';

    }, [isNetworkSetup]);

    const handleNetworkSetup = () => {
        setNetworkSetup(!isNetworkSetup);
        console.log(!isNetworkSetup)
    };

    return (
        <div id="networksetup">
            <input
                type="checkbox"
                id="showNetworkSetup"
                checked={isNetworkSetup} // Use checked attribute for controlled behavior
                onChange={handleNetworkSetup}
            />
            <label htmlFor="showNetworkSetup">Setup Network</label>
        </div>
    );
};

export default NetworkSetup;

