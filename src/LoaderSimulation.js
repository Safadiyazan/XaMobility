import React, { useEffect } from 'react';
import * as Cesium from "cesium";
import { Model, IonResource, ClockStep, ClockRange, HeadingPitchRoll, VelocityOrientationProperty, PathGraphics, DistanceDisplayCondition, CallbackProperty, TimeInterval, TimeIntervalCollection, SampledPositionProperty, JulianDate, Cartographic, Sun, ShadowMode, Color, Ellipsoid, Matrix4, Transforms, Cesium3DTileset, Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import "cesium/Build/Cesium/Widgets/widgets.css";
import ViewerToolBar from './components/ViewerToolBar';
import NetworkSetup from './components/NetworkSetup.js';
import './css/main.css'; // Ensure this import is here

// =================================================================================================================================================
// Cesium Simulation
// =================================================================================================================================================

export async function LoadSimulation(viewer, data, city) {
    try {
        viewer.entities.removeAll();
    } catch (error) {
        console.log(`Error loading
      ${error}`);
    }
    var NavigationOn = true;

    ///////////////////////////////////////////////////////////////////////////////////////
    // Functions
    // Function to calculate a new point given offsets in meters
    function computeNewPoint(center, dx, dy, dz) {
        // Create a matrix that represents the east, north, up AGL offset
        var offsetMatrix = Transforms.eastNorthUpToFixedFrame(center, Ellipsoid.WGS84, new Matrix4());
        // Offset the point by the specified distances
        var offsetPoint = Matrix4.multiplyByPoint(offsetMatrix, new Cartesian3(dx, dy, dz), new Cartesian3());
        return offsetPoint;
    }
    // Function to plot Point as black dot circle
    function plotPoint(newPoint) {
        // Create a point entity at the new position
        const scene = viewer.scene;
        var ellipsoid = scene.globe.ellipsoid;
        var PointCatroStr = Cartographic.fromCartesian(newPoint, ellipsoid)
        viewer.entities.add({
            name: `Point`,
            description: `Location: (${CesiumMath.toDegrees(PointCatroStr.longitude)}, ${CesiumMath.toDegrees(PointCatroStr).latitude}, ${PointCatroStr.height})`,
            position: newPoint,
            point: {
                pixelSize: 5,
                color: Color.BLACK,
                outlineColor: Color.WHITE,
                outlineWidth: 1,
            },
            allowPicking: false,
        });
        return undefined;
    }
    ///////////////////////////////////////////////////////////////////////////////////////
    // Center point
    switch (city) {
        case "NYC":
            if ((data.Settings.Airspace.Vertiports !== undefined) && (data.Settings.Airspace.Vertiports === 1)) {
                var dz0 = 0;
            } else {
                var dz0 = 480;
            }
            var center = Cartesian3.fromDegrees(-73.98435971601633, 40.75171803897241, dz0); // NYC
            break;
        case "SF":
            var dz0 = 80;
            var center = Cartesian3.fromDegrees(-122.3816, 37.6191, dz0); // SF
            break;
        case "ZH":
            var dz0 = 580;
            var center = Cartesian3.fromDegrees(8.545094, 47.373878, dz0); // Zurich
            break;
        case "HF":
            var dz0 = 580;
            var center = Cartesian3.fromDegrees(35.023484, 32.777805, dz0); // NAZ
            break;
        case "NZ":
            var dz0 = 580;
            var center = Cartesian3.fromDegrees(35.29755740551859, 32.702149095841264, dz0); // NAZ
            break;
        case "DXB":
            var dz0 = 80;
            var center = Cartesian3.fromDegrees(55.1390, 25.1124, dz0); // Dubai
            break;
        case "KTH":
            var dz0 = 580;
            var center = Cartesian3.fromDegrees(18.070336, 59.349744, dz0); // Dubai
            break;
        case "UOM":
            var dz0 = 580;
            var center = Cartesian3.fromDegrees(-83.73826609087581, 42.28074004295685, dz0); // Dubai
            break;
        // default:
        //     var dz0 = 80;
        //     var center = Cartesian3.fromDegrees(-73.98435971601633, 40.75171803897241, dz0); // NYC
    }

    // var center = Cartesian3.fromDegrees(35.045628640781565, 32.77278697558125,  dz0); // NESHER
    // var center = Cartesian3.fromDegrees(35.01178943640926, 32.76765420453765,  dz0); // HAIFA

    ///////////////////////////////////////////////////////////////////////////////////////
    // Define handleCheckboxChange in the global scope
    // window.handleCheckboxChange = function () {
    //     var isChecked = document.getElementById('customCheckbox').checked;
    //     var NavigationOn = isChecked;
    //     console.log(NavigationOn)
    //     ViewSetting(center, NavigationOn);
    //     console.log('Checkbox Checked:', isChecked);
    // };

    // function createCustomControls(viewer) {
    //     var customControlsDiv = document.createElement('div');
    //     customControlsDiv.id = 'customControls';
    //     customControlsDiv.style.position = 'absolute';
    //     customControlsDiv.style.top = '50px';
    //     customControlsDiv.style.right = '10px';
    //     customControlsDiv.style.zIndex = '1000';
    //     customControlsDiv.innerHTML = `
    //       <input type="checkbox" id="customCheckbox" onchange="handleCheckboxChange()">
    //       <label for="customCheckbox"> Navigation Keyboard On</label>
    //     `;

    //     viewer.container.appendChild(customControlsDiv);
    // }
    // createCustomControls(viewer);
    var randomNumberVerti = 0;
    ///////////////////////////////////////////////////////////////////////////////////////
    ViewSetting(center, NavigationOn);
    function ViewSetting(center, NavigationOn) {
        viewer.scene.globe.enableLighting = true; // Enable lighting for the sun and shadows
        viewer.shadows = true; // Enable shadows

        // Set shadow mode (for example, to have both terrain and 3D models cast and receive shadows):
        viewer.scene.shadowMode = ShadowMode.ENABLED;

        // You can also specify how detailed the shadows should be (higher quality may impact performance):
        viewer.shadowMap.maximumDistance = 5000.0; // Maximum shadow distance in meters

        // Create a light source for the sun
        // var sunLight = new Sun();

        // Set the light source direction (optional, the default is the sun's position)
        // sunLight.direction = Cartesian3.normalize(new Cartesian3(0.5, 0.5, 0.5), new Cartesian3());

        // Add the light source to the scene
        // viewer.scene.sun = sunLight;
        // Fly the camera to San Francisco at the given longitude, latitude, and height.
        var initialPosition = computeNewPoint(center, 0, -1250, 2000);
        var initialOrientation = {
            heading: CesiumMath.toRadians(0.0),
            pitch: CesiumMath.toRadians(-60.0),
            roll: CesiumMath.toRadians(0),
        };
        viewer.camera.flyTo({
            destination: initialPosition,
            orientation: {
                heading: initialOrientation.heading,
                pitch: initialOrientation.pitch,
            },
            duration: 20,
        });
        var camera = viewer.camera;

        // Add event listeners to track key state
        function onKeyDown(event) {
            keyState[event.key] = true;
            if ((event.key === 'ArrowUp' || event.key === 'ArrowDown' || event.key === 'ArrowLeft' || event.key === 'ArrowRight' || event.key === 'PageUp' || event.key === 'PageDown')) {
                event.preventDefault(); // Prevent scrolling when arrow keys are pressed
            }
            if ((event.key === 'N')) {
                isNetworkSetup = !isNetworkSetup; // Toggle the variable
                handleNetworkSetup(isNetworkSetup);
            }
            if ((event.key === 'h')) {
                // Reset camera to initial position and orientation
                pitch = initialOrientation.pitch;
                roll = initialOrientation.roll;
                yaw = initialOrientation.heading;
                height = initialPosition.height;
                camera.flyTo({
                    destination: initialPosition,
                    orientation: initialOrientation,
                });
                // viewer.zoomTo(airspace)
                viewer.trackedEntity = undefined;
            }
            if ((event.key === 'V')) {
                randomNumberVerti = Math.floor(Math.random() * VertiportArray.length);
                viewer.trackedEntity = VertiportArray[randomNumberVerti];
            }
            if ((event.key === '!')) {
                randomNumberVerti = 0;
                viewer.trackedEntity = VertiportArray[randomNumberVerti];
            }
            if ((event.key === '@')) {
                randomNumberVerti = 1;
                viewer.trackedEntity = VertiportArray[randomNumberVerti];
            }
            if ((event.key === '#')) {
                randomNumberVerti = 2;
                viewer.trackedEntity = VertiportArray[randomNumberVerti];
            }
            if ((event.key === '$')) {
                randomNumberVerti = 3;
                viewer.trackedEntity = VertiportArray[randomNumberVerti];
            }
            if ((event.key === '+')) {
                VertiportArray[randomNumberVerti] = rotateEntity(VertiportArray[randomNumberVerti],5);
            }
            if ((event.key === 'r')) {
                var randomNumber = Math.floor(Math.random() * entitiesArray.length);
                var FindEntity = 1;
                var counterWhile = 1;
                while ((counterWhile < 100) && (FindEntity)) {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        viewer.trackedEntity = entitiesArray[randomNumber];
                        viewer.clock.onTick.addEventListener((clock) => {
                            if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                                const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                                const formattedTime = new Date(viewer.clock.currentTime);
                                const time0 = entitiesArray[randomNumber].availability.start;
                                const time2 = viewer.clock.currentTime;
                                const position0 = positionPropertyArray[randomNumber].getValue(time0);
                                const position2 = positionPropertyArray[randomNumber].getValue(time2);
                                const distance = Cartesian3.distance(position0, position2);
                                const timeDifference = JulianDate.secondsDifference(time2, time0);
                                const speed = distance / timeDifference;
                                const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                                const microtoolbar = document.getElementById('microtoolbar');
                                microtoolbar.innerHTML = tableHtml;
                            } else {
                                const tableHtml = `
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
                                        `;
                                const microtoolbar = document.getElementById('microtoolbar');
                                microtoolbar.innerHTML = tableHtml;
                            }
                            ;
                        });

                        FindEntity = 0;
                    } else {
                        randomNumber = Math.floor(Math.random() * entitiesArray.length);
                        counterWhile = counterWhile + 1;
                    }
                }
            }
            if ((event.key === '1')) {
                var randomNumber = 1 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === '2')) {
                var randomNumber = 2 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === '3')) {
                var randomNumber = 3 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === '4')) {
                var randomNumber = 4 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === '5')) {
                var randomNumber = 5 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === '6')) {
                var randomNumber = 6 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === '7')) {
                var randomNumber = 7 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === '8')) {
                var randomNumber = 8 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === '9')) {
                var randomNumber = 9 - 1;
                viewer.trackedEntity = entitiesArray[randomNumber];
                viewer.clock.onTick.addEventListener((clock) => {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        const cartographic = Cartographic.fromCartesian(positionPropertyArray[randomNumber].getValue(viewer.clock.currentTime));
                        const formattedTime = new Date(viewer.clock.currentTime);
                        const time0 = entitiesArray[randomNumber].availability.start;
                        const time2 = viewer.clock.currentTime;
                        const position0 = positionPropertyArray[randomNumber].getValue(time0);
                        const position2 = positionPropertyArray[randomNumber].getValue(time2);
                        const distance = Cartesian3.distance(position0, position2);
                        const timeDifference = JulianDate.secondsDifference(time2, time0);
                        const speed = distance / timeDifference;
                        const tableHtml = `
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
                                            <td>${randomNumber + 1}</td>
                                        </tr>
                                        <tr>
                                            <td>Time</td>
                                            <td>${formattedTime.toLocaleTimeString()}</td>
                                        </tr>
                                        <tr>
                                            <td>Longitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.longitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Latitude</td>
                                            <td>${CesiumMath.toDegrees(cartographic.latitude).toFixed(4)} [deg]</td>
                                        </tr>
                                        <tr>
                                            <td>Height</td>
                                            <td>${cartographic.height.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Flight time</td>
                                            <td>${timeDifference.toFixed(2)} [s]</td>
                                        </tr>
                                        <tr>
                                            <td>Distance travelled</td>
                                            <td>${distance.toFixed(2)} [m]</td>
                                        </tr>
                                        <tr>
                                            <td>Speed</td>
                                            <td>${speed.toFixed(2)} [m/s]</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                    `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    } else {
                        const tableHtml = `
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
                                        `;
                        const microtoolbar = document.getElementById('microtoolbar');
                        microtoolbar.innerHTML = tableHtml;
                    }
                    ;
                });
            }
            if ((event.key === 'f')) {
                var randomNumber = Math.floor(Math.random() * entitiesArray.length);
                var FindEntity = 1;
                var counterWhile = 1;
                while ((counterWhile < 100) && (FindEntity)) {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        viewer.zoomTo(entitiesArray[randomNumber]);
                        FindEntity = 0;
                    } else {
                        randomNumber = Math.floor(Math.random() * entitiesArray.length);
                        counterWhile = counterWhile + 1;
                    }
                }
            }

        }
        function onKeyUp(event) {
            keyState[event.key] = false;
        }


        // Define variables to control flight dynamics
        var pitchRate = 0.04;  // Rate of pitch change
        var rollRate = 0.04;   // Rate of roll change
        var yawRate = 0.04;    // Rate of yaw change
        var moveSpeed = 30.0; // Rate of translation (movement)
        var heightAdjustmentSpeed = 5.0; // Speed of height adjustment
        // Initialize variables for tracking aircraft orientation
        var pitch = initialOrientation.pitch; // Initial pitch value
        var roll = initialOrientation.roll; // Initial roll value
        var yaw = initialOrientation.heading; // Initial yaw value
        var height = initialPosition.height;
        // Set up flags to track key presses
        var keyState = {
            'w': false,
            's': false,
            'a': false,
            'd': false,
            'q': false,
            'e': false,
            'ArrowUp': false,
            'ArrowDown': false,
            'ArrowLeft': false,
            'ArrowRight': false,
            'PageUp': false,
            'PageDown': false,
        };
        window.addEventListener('keydown', onKeyDown);
        window.addEventListener('keyup', onKeyUp);
        // Create a function to handle movement
        function handleMovement() {
            if (!NavigationOn) {
                // Stop movement if NavigationOn is false
                console.log('keyboard is off.');
                keyState = {};
                window.removeEventListener('keydown', onKeyDown);
                window.removeEventListener('keyup', onKeyUp);
                return; // Exit the function if NavigationOn is false
            }
            if (keyState['w']) {
                // Pitch up
                pitch += pitchRate;
            }
            if (keyState['s']) {
                // Pitch down
                pitch -= pitchRate;
            }
            if (keyState['a']) {
                // Roll left
                roll += rollRate;
            }
            if (keyState['d']) {
                // Roll right
                roll -= rollRate;
            }
            if (keyState['q']) {
                // Yaw left
                yaw += yawRate;
            }
            if (keyState['e']) {
                // Yaw right
                yaw -= yawRate;
            }
            if (keyState['ArrowUp']) {
                // Move forward
                camera.moveForward(moveSpeed);
            }
            if (keyState['ArrowDown']) {
                // Move backward
                camera.moveBackward(moveSpeed);
            }
            if (keyState['ArrowLeft']) {
                // Move left
                camera.moveLeft(moveSpeed);
            }
            if (keyState['ArrowRight']) {
                // Move right
                camera.moveRight(moveSpeed);
            }
            if (keyState['PageUp']) {
                // Increase height
                camera.moveUp(heightAdjustmentSpeed);
            }
            if (keyState['PageDown']) {
                // Decrease height
                camera.moveDown(heightAdjustmentSpeed);
            }
            // Apply the aircraft orientation
            camera.setView({
                orientation: {
                    pitch: pitch,
                    roll: roll,
                    heading: yaw,
                },
            });
            viewer.render();
            // Continue handling movement
            requestAnimationFrame(handleMovement);
        }
        if (NavigationOn) {
            handleMovement();
        }
    }
    // (Optional) Add event listeners for interactive elements (checkboxes, etc.)
    // End view settings
    ///////////////////////////////////////////////////////////////////////////////////////
    // Start Layers and Region Settings.
    var dx = data.Settings.dx;
    var dy = data.Settings.dy;
    var dz = data.Settings.dz;
    var dz1 = data.Settings.Airspace.dz1;
    var as;
    if (data.Settings.as !== undefined) {
        as = data.Settings.as;
    } else {
        as = 2;
    }

    function PlotCube(CubeCC, CubeDx, CubeDy, CubeDz, CubeDz0, CubeDz1, nameStr, ColorStr, outlineColorStr) {
        const centerPlotting = computeNewPoint(CubeCC, 0, 0, 0);
        plotPoint(centerPlotting);
        var newPointSE = computeNewPoint(centerPlotting, CubeDx / 2, -CubeDy / 2, 0); plotPoint(newPointSE);
        var newPointNE = computeNewPoint(centerPlotting, CubeDx / 2, CubeDy / 2, 0); plotPoint(newPointNE);
        var newPointSW = computeNewPoint(centerPlotting, -CubeDx / 2, -CubeDy / 2, 0); plotPoint(newPointSW);
        var newPointNW = computeNewPoint(centerPlotting, -CubeDx / 2, CubeDy / 2, 0); plotPoint(newPointNW);
        var newPointSEUP = computeNewPoint(centerPlotting, CubeDx / 2, -CubeDy / 2, CubeDz); plotPoint(newPointSEUP);
        var newPointNEUP = computeNewPoint(centerPlotting, CubeDx / 2, CubeDy / 2, CubeDz); plotPoint(newPointNEUP);
        var newPointSWUP = computeNewPoint(centerPlotting, -CubeDx / 2, -CubeDy / 2, CubeDz); plotPoint(newPointSWUP);
        var newPointNWUP = computeNewPoint(centerPlotting, -CubeDx / 2, CubeDy / 2, CubeDz); plotPoint(newPointNWUP);
        const scene = viewer.scene;
        var ellipsoid = scene.globe.ellipsoid;
        var cartographicNW = Cartographic.fromCartesian(newPointNW, ellipsoid);
        var cartographicNE = Cartographic.fromCartesian(newPointNE, ellipsoid);
        var cartographicSE = Cartographic.fromCartesian(newPointSE, ellipsoid);
        var cartographicSW = Cartographic.fromCartesian(newPointSW, ellipsoid);
        // var distance = Cartesian3.distance(newPointSE, newPointSEUP);
        // console.log("Distance between points: " + distance + " meters");
        const airspace = viewer.entities.add({
            name: nameStr,// `Airspace`,
            description: ``,
            polygon: {
                hierarchy: Cartesian3.fromDegreesArray([
                    CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                    CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                    CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                    CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                ]),
                height: CubeDz0 + CubeDz1,
                extrudedHeight: CubeDz0 + CubeDz + CubeDz1,
                material: ColorStr,//Color.CYAN.withAlpha(0.1),
                outline: true,
                outlineColor: outlineColorStr,//Color.CYAN,
            },
            allowPicking: false,
        });
        //viewer.zoomTo(airspace);
    }
    PlotCube(center, dx, dy, dz, dz0, dz1, 'Airspace', Color.BLACK.withAlpha(0.1), Color.BLACK);
    if (data.Settings.Airspace.VTOL === 1) {
        PlotCube(center, dx, dy, dz1, dz0, 0, 'VTOLLayer', Color.RED.withAlpha(0.05), Color.RED);
    }
    try {
        data.Settings.Airspace.Layers.forEach((L, index) => {
            // console.log(computeNewPoint(center, L.center[1],L.center[2],L.center[3]),L.dx,L.dy,L.dz,dz0,dz1)
            PlotCube(computeNewPoint(center, L.center[0], L.center[1], L.center[2] - L.dz / 2), L.dx, L.dy, L.dz, dz0 + L.center[2] - L.dz / 2, 0, ['Layer ' + index], Color.CYAN.withAlpha(0.005), Color.CYAN.withAlpha(0.2))
        });
    } catch (error) {
        console.log(`Error loading ${error}`);
    }
    try {
        data.Settings.Airspace.Regions.B.forEach((R, index) => {
            // console.log(computeNewPoint(center, L.center[1],L.center[2],L.center[3]),L.dx,L.dy,L.dz,dz0,dz1)
            if (R.ri === 1 || R.ri === 11 || R.ri === 21 || R.ri === 31) {
                PlotCube(computeNewPoint(center, R.center[0], R.center[1], R.center[2] - R.dz / 2), R.dx, R.dy, R.dz, dz0 + R.center[2] - R.dz / 2, 0, ['Region ' + R.ri], Color.CYAN.withAlpha(0.005), Color.RED.withAlpha(0.2))
            }
        });
    } catch (error) {
        console.log(`Error loading ${error}`);
    }
    // End Layers and Regions Settings
    ///////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////
    // Start Aircraft Motion
    // Function that genreate FlightData according to shiting dpx,dpy,dpz for number of steps
    async function generateFlightData(centerPoint, numSteps, dpx, dpy, dpz) {
        var flightData = [];
        var currentPosition = centerPoint;

        for (var i = 0; i < numSteps; i++) {
            flightData.push({
                longitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).longitude),
                latitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).latitude),
                height: Cartographic.fromCartesian(currentPosition).height
            });

            // Calculate the next position by moving 10 meters east (positive x-axis)
            //var eastOffset = new Cartesian3(stepSize, 0, 0);
            //currentPosition = Cartesian3.add(currentPosition, eastOffset, new Cartesian3());
            currentPosition = computeNewPoint(currentPosition, dpx, dpy, dpz);
        }
        return flightData;
    }

    function TestFlightsFunctions(center) {
        var numSteps = 75; // numSteps * 30 seconds for motion.
        var dx = 1500; // in meters, eastward direction
        var dy = 1500; // in meters, northward direction
        var dz = 80;  // in meters, upward direction
        var dpx = 0; // 10 meters north in each step
        var dpy = 10; // 10 meters east in each step
        var dpz = 1; // 10 meters up in each step
        var newPointSE = computeNewPoint(center, dx / 2, -dy / 2, 0);
        var newPointNE = computeNewPoint(center, dx / 2, dy / 2, 0);
        var newPointSW = computeNewPoint(center, -dx / 2, -dy / 2, 0);
        var newPointNW = computeNewPoint(center, -dx / 2, dy / 2, 0);
        var flightData = generateFlightData(newPointSE, 75, 0, 10, 1);
        AddAircraftMotion(flightData, 0);
        var flightData = generateFlightData(newPointSE, 75, -15, 15, 1);
        AddAircraftMotion(flightData, 0);
        var flightData = generateFlightData(newPointSE, 75, -30, 10, 1);
        AddAircraftMotion(flightData, 0);
        var flightData = generateFlightData(newPointNE, 75, -25, -15, 1);
        AddAircraftMotion(flightData, 0);
        var flightData = generateFlightData(newPointNW, 75, 20, -15, 1);
        AddAircraftMotion(flightData, 0);
        var flightData = generateFlightData(newPointSW, 75, 25, 10, 1);
        AddAircraftMotion(flightData, 0);
        var flightData = generateFlightData(center, 75, 0, 0, -2);
        AddAircraftMotion(flightData, 1);
    }
    // TestFlightsFunctions();

    async function AddAircraftMotion(startSim, stopSim, timeStepInSeconds, AircraftIndex, flightData, AMI, statusData, tda, taa, rs, rd, vertical, entitiesArray, positionPropertyArray) {
        const startAircraft = new JulianDate.addSeconds(startSim, tda, new JulianDate());
        const stopAircraft = new JulianDate.addSeconds(startSim, taa, new JulianDate());
        const positionProperty = new SampledPositionProperty();
        const polylinePositions = [];
        // Load and draw waypoints
        for (let i = 0; i < flightData.length; i++) {
            const dataPoint = flightData[i];
            const time = JulianDate.addSeconds(startSim, i * timeStepInSeconds, new JulianDate());
            const position = Cartesian3.fromDegrees(dataPoint.longitude, dataPoint.latitude, dataPoint.height);
            positionProperty.addSample(time, position);
            polylinePositions.push(position);
            const validTime = JulianDate.lessThanOrEquals(time, stop);
            const waypointEntity = viewer.entities.add({
                name: `Aircraft: ${AircraftIndex}, Waypoint: ${i}`,
                description: `Location: (${dataPoint.longitude}, ${dataPoint.latitude}, ${dataPoint.height})`,
                position: position,
                point: {
                    pixelSize: 2,
                    color: Color.BLACK,
                    //markerSymbol: 'X'
                },
                availability: new TimeIntervalCollection([new TimeInterval({
                    start: startAircraft,
                    stop: validTime ? time : stopAircraft
                })]),
                allowPicking: false,
            });
        }

        // Draw path
        const pathEntity = viewer.entities.add({
            name: `Aircraft: ${AircraftIndex}, Waypoint Path`,
            polyline: {
                positions: polylinePositions,
                material: Color.BLACK.withAlpha(0.3),
                width: 1,
            },
            allowPicking: false,
        });
        pathEntity.availability = new TimeIntervalCollection([new TimeInterval({
            start: startAircraft,
            stop: stopAircraft
        })]);
        // Draw shortest path
        const pathShortEntity = viewer.entities.add({
            name: `Aircraft: ${AircraftIndex}, Waypoint Path`,
            polyline: {
                positions: [Cartesian3.fromDegrees(flightData[0].longitude, flightData[0].latitude, flightData[0].height),
                Cartesian3.fromDegrees(flightData[flightData.length - 1].longitude, flightData[flightData.length - 1].latitude, flightData[flightData.length - 1].height)],
                material: Color.GREEN.withAlpha(0.5),
                width: 1.5,
            },
            allowPicking: false,
        });
        pathShortEntity.availability = new TimeIntervalCollection([new TimeInterval({
            start: startAircraft,
            stop: stopAircraft
        })]);
        // Add origin entity
        const oA = flightData[0];
        const oAEntity = viewer.entities.add({
            name: `Aircraft: ${AircraftIndex}, Origin Point`,
            description: `Location: (${oA.longitude}, ${oA.latitude}, ${oA.height})`,
            position: Cartesian3.fromDegrees(oA.longitude, oA.latitude, oA.height),
            availability: new TimeIntervalCollection([new TimeInterval({ start: startAircraft, stop: stopAircraft })]),
            point: {
                pixelSize: 5,
                color: Color.GREEN,
                markerSymbol: 'O'
            },
            allowPicking: false,
        });
        // Add destiation entity
        const dA = flightData[flightData.length - 1];
        const dAEntity = viewer.entities.add({
            name: `Aircraft: ${AircraftIndex}, Destination Point`,
            description: `Location: (${dA.longitude}, ${dA.latitude}, ${dA.height})`,
            position: Cartesian3.fromDegrees(dA.longitude, dA.latitude, dA.height),
            availability: new TimeIntervalCollection([new TimeInterval({ start: startAircraft, stop: stopAircraft })]),
            point: {
                pixelSize: 5,
                color: Color.GREEN,
                markerSymbol: 'X'
            },
            allowPicking: false,
        });
        // Add travelled path until spefific time.
        const traveledPathEntity = viewer.entities.add({
            polyline: {
                name: `Aircraft: ${AircraftIndex}, Path`,
                description: ``,
                positions: new CallbackProperty(function () {
                    const currentTime = viewer.clock.currentTime;
                    const currentElapsedTime = JulianDate.secondsDifference(currentTime, startSim);
                    const currentIteration = Math.floor(currentElapsedTime / timeStepInSeconds);
                    const positionsUpToCurrentTime = [];
                    for (let i = 1; i <= currentIteration && i < flightData.length; i++) {
                        const dataPoint1 = flightData[i - 1];
                        const dataPoint2 = flightData[i];
                        const timePoint1 = JulianDate.addSeconds(startSim, (i - 1) * timeStepInSeconds, new JulianDate());
                        const timePoint2 = JulianDate.addSeconds(startSim, (i) * timeStepInSeconds, new JulianDate());
                        positionsUpToCurrentTime.push(Cartesian3.fromDegrees(dataPoint2.longitude, dataPoint2.latitude, dataPoint2.height));
                    }

                    return positionsUpToCurrentTime;
                }, false),
                width: 1.5,
                material: Color.MAGENTA.withAlpha(0.15),
                allowPicking: false,
            }
        });
        traveledPathEntity.availability = new TimeIntervalCollection([new TimeInterval({
            start: startAircraft,
            stop: stopAircraft
        })]);
        traveledPathEntity.distanceDisplayCondition = new DistanceDisplayCondition(
            0.0,
            45.5
        );
        // Add Aircraft safety radius
        const SafetySphereEntity = viewer.entities.add({
            name: `Aircraft: ${AircraftIndex}, Safety Space`,
            description: ``,
            position: positionProperty,
            ellipsoid: {
                radii: new Cartesian3(rs, rs, rs),
                material: Color.RED.withAlpha(0.1),
                outline: true,
                outlineColor: Color.BLACK.withAlpha(0.2),
            },
            allowPicking: false,
        });
        SafetySphereEntity.availability = new TimeIntervalCollection([new TimeInterval({
            start: startAircraft,
            stop: stopAircraft
        })]);
        SafetySphereEntity.distanceDisplayCondition = new DistanceDisplayCondition(
            0.0,
            45.5
        );

        // Add Aircraft detection radius
        const DetectionSphereEntity = viewer.entities.add({
            name: `Aircraft: ${AircraftIndex}, Detection Space`,
            description: ``,
            position: positionProperty,
            ellipsoid: {
                radii: new Cartesian3(rd, rd, rd),
                material: Color.BLACK.withAlpha(0.05),
                outline: true,
                outlineColor: Color.BLACK.withAlpha(0.05),
            },
            allowPicking: false,
        });
        DetectionSphereEntity.availability = new TimeIntervalCollection([new TimeInterval({
            start: startAircraft,
            stop: stopAircraft
        })]);
        DetectionSphereEntity.distanceDisplayCondition = new DistanceDisplayCondition(
            0.0,
            45.5
        );

        // Add Aircraft Model
        async function loadModel(positionProperty, entitiesArray, positionPropertyArray, AMI) {

            var AircraftURL = "/YS_VTOL.glb";
            var AircraftURLScale = 2;
            // var AircraftModelIndex = Math.floor(Math.random() * 4) + 1;
            switch (AMI) {
                case 1:
                    AircraftURL = "/YS_VTOL_Medical.glb";
                    AircraftURLScale = 2;
                    break;
                case 2:
                    AircraftURL = "/YS_Drone_MedicalCargo.glb";
                    AircraftURLScale = 1;
                    break;
                case 3:
                    AircraftURL = "/YS_VTOL.glb";
                    AircraftURLScale = 2;
                    break;
                case 4:
                    AircraftURL = "/YS_Drone_Pack.glb";
                    AircraftURLScale = 1;
                    break;
                default:
                    AircraftURL = "/YS_VTOL.glb";
                    AircraftURLScale = 2;

            }


            const airplaneEntity = viewer.entities.add({
                name: `Aircraft: ${AircraftIndex}, Model`,
                description: ``,
                position: positionProperty,
                model: {
                    // uri: airplaneUri,
                    uri: AircraftURL,
                    scale: AircraftURLScale
                },
                path: new PathGraphics({ width: 0.2 }),
                // orientation: vertical === 0 ? new VelocityOrientationProperty(positionProperty) : undefined,
                orientation: calculateOrientation(positionProperty), // Use a callback for orientation
                allowPicking: false,
            });
            airplaneEntity.availability = new TimeIntervalCollection([new TimeInterval({
                start: startAircraft,
                stop: stopAircraft
            })]);
            airplaneEntity.distanceDisplayCondition = new DistanceDisplayCondition(
                0.0,
                45.5
            );
            entitiesArray.push(airplaneEntity);
            positionPropertyArray.push(positionProperty);
            return entitiesArray, positionPropertyArray;
        }

        entitiesArray, positionPropertyArray = loadModel(positionProperty, entitiesArray, positionPropertyArray, AMI);

        function calculateOrientation(positionProperty) {

            const customOrientationProperty = new CallbackProperty((time, result) => {
                try {
                    // Maximum Values
                    const maxPitch = CesiumMath.toRadians(5); // Max pitch in radians
                    const maxRoll = CesiumMath.toRadians(5);  // Max roll in radians
                    // Extract Cuurent Orientation
                    const velocityOrientation = new VelocityOrientationProperty(positionProperty);
                    const CurrentvelocityOrientation = velocityOrientation.getValue(time);
                    // Extract pitch, roll, and yaw angles from the orientationQuaternion
                    const pitchRollYaw = new HeadingPitchRoll.fromQuaternion(CurrentvelocityOrientation);
                    // Store the initial orientation values
                    const initialOrientation = {
                        heading: pitchRollYaw.heading,
                        pitch: pitchRollYaw.pitch,
                        roll: pitchRollYaw.roll,
                        yaw: pitchRollYaw.yaw
                    };

                    // Apply pitch limits
                    const center = positionProperty.getValue(time);
                    const heading = pitchRollYaw.heading; //
                    const pitch = CesiumMath.clamp(pitchRollYaw.pitch, -maxPitch, maxPitch);; // pitchRollYaw.pitch; //
                    const roll = CesiumMath.clamp(pitchRollYaw.roll, -maxRoll, maxRoll);//  pitchRollYaw.roll; //
                    const hpr = new HeadingPitchRoll(heading, pitch, roll);
                    const modifiedOrientationQuaternion = Transforms.headingPitchRollQuaternion(center, hpr);
                    // console.log(modifiedOrientationQuaternion)
                    //return modifiedOrientationQuaternion;
                    //return orientationProperty;

                    // Check if values changed and log them
                    /*if (hpr.heading !== initialOrientation.heading || hpr.pitch !== initialOrientation.pitch ||
                    hpr.roll !== initialOrientation.roll) {
                      console.log('Orientation values changed:');
                      console.log('Initial:', initialOrientation);
                      console.log('Modified:', hpr);
                    }*/

                    return modifiedOrientationQuaternion;
                } catch (error) {
                    return undefined;//VelocityOrientationProperty(positionProperty);
                }
            }, false);

            return customOrientationProperty;


        }
    }

    ///////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    // Start Vertiport setting
    var VertiportArray = [];

    async function AddVertiport(VertiportIndex, FunVertiportLocation, FunheadingPositionRoll, FunfixedFrameTransform, VertiportArray) {
        try {
            const entityVertiport = viewer.entities.add({
                name: "Vertiport " + VertiportIndex,
                position: FunVertiportLocation,
                model: {
                    uri: "/Vertiport.glb",
                    scale: 0.5,
                    // minimumPixelSize: 128
                },
                orientation: Cesium.Transforms.headingPitchRollQuaternion(
                    FunVertiportLocation,
                    FunheadingPositionRoll,
                    Cesium.Ellipsoid.WGS84,
                    FunfixedFrameTransform
                )
            });
            VertiportArray.push(entityVertiport);
            // const modelA = await Cesium.Model.fromGltfAsync({
            //     url: "/Vertiport.glb",
            //     scale: 0.5,
            //     modelMatrix: Cesium.Transforms.headingPitchRollToFixedFrame(
            //         FunVertiportLocation,
            //         FunheadingPositionRoll,
            //         Cesium.Ellipsoid.WGS84,
            //         FunfixedFrameTransform
            //     ),
            // });
            // viewer.scene.primitives.add(modelA);

            // plotPoint(computeNewPoint(FunVertiportLocation, 0, 17.5, 2));
            // plotPoint(computeNewPoint(FunVertiportLocation, 0, -17.5, 2));
            // const VertiPortSphereEntityA = viewer.entities.add({
            //     name: 'Vertiport:'  + VertiportIndex + 'a - Safety Space',
            //     description: ``,
            //     position: computeNewPoint(FunVertiportLocation, 0, 17.5, 0),
            //     ellipsoid: {
            //         radii: new Cartesian3(15, 15, 15),
            //         material: Color.RED.withAlpha(0.1),
            //         outline: true,
            //         outlineColor: Color.BLACK.withAlpha(0.2),
            //     },
            //     allowPicking: false,
            // });
            // const VertiPortSphereEntityB = viewer.entities.add({
            //     name: 'Vertiport:'  + VertiportIndex + 'b - Safety Space',
            //     description: ``,
            //     position: computeNewPoint(FunVertiportLocation, 0, -17.5, 0),
            //     ellipsoid: {
            //         radii: new Cartesian3(15, 15, 15),
            //         material: Color.RED.withAlpha(0.1),
            //         outline: true,
            //         outlineColor: Color.BLACK.withAlpha(0.2),
            //     },
            //     allowPicking: false,
            // });
            console.log(VertiportArray)
            console.log('Added vertiport to array')
            return VertiportArray;
        } catch (error) {
            console.log(`Failed to load model. ${error}`);
        }
    }

    // function rotateEntity(entity, angleOffset) {
    //     console.log(entity.id)
    //     const currentOrientation = entity.orientation.getValue(Cesium.JulianDate.now());

    //     // Calculate new orientation (modify existing matrix)
    //     const rotation = Cesium.Matrix3.fromQuaternion(currentOrientation);
    //     const rotationMatrix = Cesium.Matrix3.fromRotationZ(Cesium.Math.toRadians(angleOffset));
    //     Cesium.Matrix3.multiply(rotation, rotationMatrix, rotation); // Modify rotation in-place

    //     // Apply new orientation
    //     entity.orientation = Cesium.Quaternion.fromRotationMatrix(rotation);
    // }
    // const VertiportLocationA = Cartesian3.fromDegrees(-73.97618892920757, 40.739661015289336, 10); // NYC NYC Health + Hospitals/Bellevue
    // const headingPositionRollA = new Cesium.HeadingPitchRoll();
    // const fixedFrameTransformA = Cesium.Transforms.localFrameToFixedFrameGenerator("north", "west");
    // AddVertiport(VertiportLocationA, headingPositionRollA, fixedFrameTransformA)
    ////////////////////////////////////////////
    // Add vertiports.
    var scene = viewer.scene;
    // scene.globe.depthTestAgainstTerrain = true;
    if (!scene.pickPositionSupported) {
        window.alert("This browser does not support pickPosition.");
    }
    if (!scene.sampleHeightSupported) {
        window.alert("This browser does not support sampleHeight.");
    }
    // var scene = this.viewer.scene;
    var ellipsoid = scene.globe.ellipsoid;
    var handler = new Cesium.ScreenSpaceEventHandler(scene.canvas);

    var isNetworkSetup = false; //document.getElementById('showNetworkSetup').checked;

    function handleNetworkSetup(isNetworkSetup) {
        if (isNetworkSetup) {
            // Pickup location 
            // Mouse over the globe to see the cartographic position
            // handler = new Cesium.ScreenSpaceEventHandler(scene.canvas);
            const labelEntity = viewer.entities.add({
                label: {
                    show: false,
                    showBackground: true,
                    font: "14px Latin Modern",
                    horizontalOrigin: Cesium.HorizontalOrigin.LEFT,
                    verticalOrigin: Cesium.VerticalOrigin.TOP,
                    // pixelOffset: new Cesium.Cartesian2(15, 0),
                },
            });

            handler.setInputAction(function (movement) {
                let foundPosition = false;

                const scene = viewer.scene;
                if (scene.mode !== Cesium.SceneMode.MORPHING) {
                    if (scene.pickPositionSupported) {
                        const cartesian = viewer.scene.pickPosition(
                            movement.endPosition
                        );

                        if (Cesium.defined(cartesian)) {
                            const cartographic = Cesium.Cartographic.fromCartesian(
                                cartesian
                            );
                            const longitudeString = Cesium.Math.toDegrees(
                                cartographic.longitude
                            ).toFixed(2);
                            const latitudeString = Cesium.Math.toDegrees(
                                cartographic.latitude
                            ).toFixed(2);
                            const heightString = cartographic.height.toFixed(2);

                            labelEntity.position = cartesian;
                            labelEntity.label.show = true;
                            labelEntity.label.text =
                                `Lon: ${`   ${longitudeString}`.slice(-7)}\u00B0` +
                                `\nLat: ${`   ${latitudeString}`.slice(-7)}\u00B0` +
                                `\nAlt: ${`   ${heightString}`.slice(-7)}m`;

                            labelEntity.label.eyeOffset = new Cesium.Cartesian3(
                                0.0,
                                0.0,
                                -cartographic.height *
                                (scene.mode === Cesium.SceneMode.SCENE2D ? 1.5 : 1.0)
                            );

                            foundPosition = true;
                        }
                    }
                }

                if (!foundPosition) {
                    labelEntity.label.show = false;
                }
            }, Cesium.ScreenSpaceEventType.MOUSE_MOVE);

            handler.setInputAction(function (event) {
                var cartesian = scene.camera.pickEllipsoid(event.position, ellipsoid);
                const lonLat = Cesium.Cartographic.fromCartesian(cartesian);
                const longitudeDeg = Cesium.Math.toDegrees(lonLat.longitude);
                const latitudeDeg = Cesium.Math.toDegrees(lonLat.latitude);
                const cartographic = new Cesium.Cartographic();
                const objectsToExclude = [];
                cartographic.longitude = lonLat.longitude;
                cartographic.latitude = lonLat.latitude;
                let Checkheight;
                if (scene.sampleHeightSupported) {
                    Checkheight = scene.sampleHeight(cartographic, objectsToExclude);
                }
                if (Cesium.defined(Checkheight)) {
                    cartographic.height = Checkheight;
                }
                const heightDeg = cartographic.height;
                const adjustedCartesian = Cesium.Cartesian3.fromRadians(cartographic.longitude, cartographic.latitude, cartographic.height); // Adjust height
                addObjectAndSaveData(adjustedCartesian, longitudeDeg, latitudeDeg, heightDeg, VertiportArray);

            }, Cesium.ScreenSpaceEventType.LEFT_DOUBLE_CLICK);




            // function addObjectAndSaveData(cartesian, longitudeDeg, latitudeDeg, heightDeg) {
            //     try {
            //         const VertiportLocation = cartesian;
            //         const headingPositionRollVertiport = new Cesium.HeadingPitchRoll();
            //         const fixedFrameTransformVertiport = Cesium.Transforms.localFrameToFixedFrameGenerator("north", "west");
            //         AddVertiport(VertiportLocation, headingPositionRollVertiport, fixedFrameTransformVertiport)
            //         // const point = viewer.entities.add({
            //         //     name: ['Vertiport:' + longitudeDeg, latitudeDeg, heightDeg],
            //         //     position: VertiportLocation,
            //         //     point: {
            //         //         color: Cesium.Color.RED,
            //         //         pixelSize: 30,
            //         //     },
            //         // });
            //         console.log('Added vertiport at ' + longitudeDeg, latitudeDeg, heightDeg)
            //         // return modelVertipot;
            //     } catch (error) {
            //         console.error("Error loading model:", error);
            //     }

            // }

            function calculateNEUDistances(center, vertiportLocation) {
                const transformMatrix = Cesium.Transforms.eastNorthUpToFixedFrame(center);
                const inverseTransformMatrix = Cesium.Matrix4.inverse(transformMatrix, new Cesium.Matrix4());

                const localPosition = new Cesium.Cartesian3();
                Cesium.Matrix4.multiplyByPoint(inverseTransformMatrix, vertiportLocation, localPosition);

                return {
                    north: localPosition.y,
                    east: localPosition.x,
                    up: localPosition.z
                };
            }
            const vertiportData = [];
            var VertiportIndex = 0;

            function addObjectAndSaveData(cartesian, longitudeDeg, latitudeDeg, heightDeg, VertiportArray) {
                try {
                    const VertiportLocation = cartesian;
                    const headingPositionRollVertiport = new Cesium.HeadingPitchRoll();
                    const fixedFrameTransformVertiport = Cesium.Transforms.localFrameToFixedFrameGenerator("north", "west");
                    VertiportArray = AddVertiport(VertiportIndex, VertiportLocation, headingPositionRollVertiport, fixedFrameTransformVertiport, VertiportArray);
                    const neuDistances = calculateNEUDistances(center, VertiportLocation);

                    // Save vertiport data
                    const vertiportInfo = {
                        index: VertiportIndex,
                        longitude: longitudeDeg,
                        latitude: latitudeDeg,
                        height: heightDeg,
                        cartesian: {
                            x: cartesian.x,
                            y: cartesian.y,
                            z: cartesian.z
                        },
                        orientation: VertiportArray[VertiportIndex].orientation,
                        neuDistances: neuDistances,
                    };
                    vertiportData.push(vertiportInfo);
                    console.log('Added vertiport at ' + longitudeDeg, latitudeDeg, heightDeg);
                    console.log('Distance of vertiport from cetner ' + neuDistances.north, neuDistances.east, neuDistances.up);

                    // Send vertiport data to the server
                    saveVertiportData(vertiportData);
                    VertiportIndex = VertiportIndex + 1;
                    return VertiportArray;
                } catch (error) {
                    console.error("Error loading model:", error);
                }
            }

            function saveVertiportData(data) {
                fetch('/api/save_vertiports', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ vertiportData: data }),
                })
                    .then(response => response.json())
                    .then(data => console.log('Server response:', data))
                    .catch(error => console.error('Error:', error));
            }
        } else {
            // labelEntity.label.show = false;
            handler.setInputAction(function (movement) {
                // console.log('Network Setup is off')
            }, Cesium.ScreenSpaceEventType.MOUSE_MOVE);
            handler.setInputAction(function (event) {
                console.log('Network Setup is off')
            }, Cesium.ScreenSpaceEventType.LEFT_DOUBLE_CLICK);
        }
    }
    // const VertiportLocationB = Cartesian3.fromDegrees(-73.98795424274152, 40.71316991516138, 30); // NYC Gotham Hospital

    // Function to rotate a specific entity
    function rotateEntity(entityRotated, angleOffset) {
        console.log(entityRotated)
        console.log('Rotating in' + angleOffset + 'degrees')
        const currentOrientation = entityRotated.orientation.getValue(Cesium.JulianDate.now());

        // Calculate new orientation
        const rotation = Cesium.Matrix3.fromQuaternion(currentOrientation);
        const rotationMatrix = Cesium.Matrix3.fromRotationZ(Cesium.Math.toRadians(angleOffset));
        const newRotation = Cesium.Matrix3.multiply(rotation, rotationMatrix, new Cesium.Matrix3());

        // Apply new orientation
        entityRotated.orientation = Cesium.Quaternion.fromRotationMatrix(newRotation);
        return entityRotated;
    }
    // Load setting if needed.
    if ((data.Settings.Airspace.Vertiports !== undefined) && (data.Settings.Airspace.Vertiports === 1)) {
        // Fetch and load fixed vertiport settings from JSON file
        fetch('/FixedVertiportsSettings.json')
            .then(response => response.json())
            .then(data => {
                data.forEach(vertiport => {
                    const FunVertiportLocation = Cesium.Cartesian3.fromDegrees(
                        vertiport.longitude,
                        vertiport.latitude,
                        vertiport.height
                    );
                    const headingPositionRoll = new Cesium.HeadingPitchRoll();
                    const fixedFrameTransform = Cesium.Transforms.localFrameToFixedFrameGenerator("north", "west");
                    AddVertiport(vertiport.index, FunVertiportLocation, headingPositionRoll, fixedFrameTransform, VertiportArray);
                });
            })
            .catch(error => console.error('Error loading fixed vertiport settings:', error));
    }

    // End Vertiport setting
    ///////////////////////////////////////////////////////////////////////////////////////


    //async function main() {
    // Add Aircraft Data from the simulation
    const dtS = data.SimInfo.dtS;
    const tf = data.SimInfo.tf / dtS;
    const timeStepInSeconds = 10 * dtS; // for objects dt Plotting, every 00 seconds.
    const dt = timeStepInSeconds / dtS; // for importing.
    const totalSeconds = data.SimInfo.tf;//timeStepInSeconds * (tf - 1);
    const startSim = JulianDate.fromIso8601("2024-07-16T09:30:00-04:00");
    const stopSim = JulianDate.addSeconds(startSim, totalSeconds, new JulianDate());
    viewer.clock.startTime = startSim.clone();
    viewer.clock.stopTime = stopSim.clone();
    viewer.clock.currentTime = startSim.clone();
    viewer.timeline.zoomTo(startSim, stopSim);
    viewer.clock.multiplier = 2;
    viewer.clock.shouldAnimate = false;
    viewer.clock.clockRange = ClockRange.CLAMPED;
    viewer.clock.clockStep = ClockStep.SYSTEM_CLOCK_MULTIPLIER;

    const currentTime = viewer.clock.currentTime;

    var entitiesArray = [];
    var positionPropertyArray = [];

    data.ObjAircraft.forEach((ObjAircraft, index) => {
        if ((index > 0) & (index < 150)) {
            //const startAircraft = new JulianDate.addSeconds(startSim, ObjAircraft.tda, new JulianDate());
            //const stopAircraft = new JulianDate.addSeconds(startSim, ObjAircraft.taa, new JulianDate());
            const trajectoryPositions = [];
            for (let i = 0; i < ObjAircraft.x.length; i += dt) {
                const currentPosition = computeNewPoint(center, ObjAircraft.x[i], ObjAircraft.y[i], ObjAircraft.z[i]);
                trajectoryPositions.push({
                    longitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).longitude),
                    latitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).latitude),
                    height: Cartographic.fromCartesian(currentPosition).height
                });
            } // IF INDEX END
            AddAircraftMotion(startSim, stopSim, timeStepInSeconds, index + 1, trajectoryPositions, ObjAircraft.AMI, ObjAircraft.status, ObjAircraft.tda, ObjAircraft.taa, ObjAircraft.rs, ObjAircraft.rd, 0, entitiesArray, positionPropertyArray);
        }
    });

    // // const url = "/Cesium_Man.glb";
    // const url = "/CesiumMilkTruck.glb";
    // // const resource = await IonResource.fromAssetId(2461035);

    // const entity = (viewer.trackedEntity = viewer.entities.add({
    //     name: url,
    //     position: positionProperty,
    //     model: {
    //         uri: url,
    //         scale: 1.0
    //     },
    // }));
    // entitiesArray.push(entity);
    // return entitiesArray;

    // Cesium Main End
    //};
}

//   // LoadSimulation(selectedFilename);
//   // End Simulation
//   fetch('/LAATSimData/SimOutput_ObjAircraft.json')
//     .then(response => response.json())
//     .then(data => {
//       LoadSimulation(viewer,data);
//     })
//     .catch(error => {
//       console.error('Error fetching data:', error);
//     });
// =================================================================================================================================================

// Export the function to make it available outside this file
// module.exports = LoadSimulation;