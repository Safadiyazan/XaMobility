import React, { useState, useEffect } from 'react';
import { IonResource, ClockStep, ClockRange, HeadingPitchRoll, VelocityOrientationProperty, PathGraphics, DistanceDisplayCondition, CallbackProperty, TimeInterval, TimeIntervalCollection, SampledPositionProperty, JulianDate, Cartographic, Sun, ShadowMode, Color, Ellipsoid, Matrix4, Transforms, Cesium3DTileset, Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import { Button } from 'react-bootstrap';
import { LoadSimulation } from '.././LoaderSimulation';

const ViewerToolBar = ({ }) => {

    const [isToolbarVisible, setIsToolbarVisible] = useState(true);

    useEffect(() => {
        // Executed only once after the component renders
        const toolbar = document.getElementById('microtoolbar');
        toolbar.style.display = isToolbarVisible ? 'block' : 'none';
    }, [isToolbarVisible]);

    const handleToolbarToggle = () => {
        setIsToolbarVisible(!isToolbarVisible);
    };

    return (
        <div id="macrotoolbar">
            <input
                type="checkbox"
                id="showToolbar"
                checked={isToolbarVisible} // Use checked attribute for controlled behavior
                onChange={handleToolbarToggle}
            />
            <label htmlFor="showToolbar">Show Info</label>
            <div id="microtoolbar">
                <table id="aircraft-data-table">
                    <thead>
                        <tr>
                            <th>Parameter</th>
                            <th>Value</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Aircraft ID</td>
                            <td>N/A</td>
                        </tr>
                        <tr>
                            <td>Time</td>
                            <td>N/A</td>
                        </tr>
                        <tr>
                            <td>Longitude</td>
                            <td>N/A [deg]</td>
                        </tr>
                        <tr>
                            <td>Latitude</td>
                            <td>N/A [deg]</td>
                        </tr>
                        <tr>
                            <td>Height</td>
                            <td>N/A [m]</td>
                        </tr>
                        <tr>
                            <td>Flight time</td>
                            <td>N/A [s]</td>
                        </tr>
                        <tr>
                            <td>Distance travelled</td>
                            <td>N/A [m]</td>
                        </tr>
                        <tr>
                            <td>Speed</td>
                            <td>N/A [m/s]</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default ViewerToolBar;

