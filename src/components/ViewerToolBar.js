import React, { useState, useEffect } from 'react';
import { IonResource, ClockStep, ClockRange, HeadingPitchRoll, VelocityOrientationProperty, PathGraphics, DistanceDisplayCondition, CallbackProperty, TimeInterval, TimeIntervalCollection, SampledPositionProperty, JulianDate, Cartographic, Sun, ShadowMode, Color, Ellipsoid, Matrix4, Transforms, Cesium3DTileset, Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import { Button } from 'react-bootstrap';
import { LoadSimulation } from '.././LoaderSimulation';

const ViewerToolBar = ({ }) => {
    // if (randomNumber) {
    // const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
    // console.log("Aircraft ID:", randomNumber+1);
    // const formattedTime = new Date(viewer.clock.currentTime);
    // console.log("Current time:", formattedTime.toLocaleTimeString());
    // console.log("Longitude:", CesiumMath.toDegrees(cartographic.longitude).toFixed(4), "degrees");
    // console.log("Latitude:", CesiumMath.toDegrees(cartographic.latitude).toFixed(4), "degrees");
    // console.log("Height:", cartographic.height.toFixed(2), "meters"); // Adjust units if needed
    // const time0 = entitiesArray[randomNumber].availability.start; // Get position 10 seconds earlier
    // const time2 = viewer.clock.currentTime;
    // const position0 = positionPropertyArray[randomNumber].getValue(time0);
    // const position2 = positionPropertyArray[randomNumber].getValue(time2);
    // const distance = Cartesian3.distance(position0, position2);
    // const timeDifference = JulianDate.secondsDifference(time2,time0);
    // console.log("Flight time:", timeDifference.toFixed(2), "second"); // Adjust units if needed
    // console.log("Distance travelled:", distance.toFixed(2), "meters"); // Adjust units if needed
    // const speed = distance / timeDifference;
    // console.log("Aircraft speed:", speed.toFixed(2), "meters per second"); // Adjust units if needed
    // } else {
    //     console.log("data unavailable for calculation");
    // }


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
            <label htmlFor="showToolbar">Show Toolbar</label>
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
                            <td>0</td>
                        </tr>
                        <tr>
                            <td>Time</td>
                            <td>0</td>
                        </tr>
                        <tr>
                            <td>Longitude</td>
                            <td>0 [deg]</td>
                        </tr>
                        <tr>
                            <td>Latitude</td>
                            <td>0 [deg]</td>
                        </tr>
                        <tr>
                            <td>Height</td>
                            <td>0 [m]</td>
                        </tr>
                        <tr>
                            <td>Flight time</td>
                            <td>0 [s]</td>
                        </tr>
                        <tr>
                            <td>Distance travelled</td>
                            <td>0 [m]</td>
                        </tr>
                        <tr>
                            <td>Speed</td>
                            <td>0 [m/s]</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default ViewerToolBar;

