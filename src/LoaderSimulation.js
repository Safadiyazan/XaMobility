import React, { useEffect } from 'react';
import * as Cesium from "cesium";
import { Model, IonResource, ClockStep, ClockRange, HeadingPitchRoll, Quaternion, PolylineDashMaterialProperty, VelocityOrientationProperty, PathGraphics, DistanceDisplayCondition, CallbackProperty, TimeInterval, TimeIntervalCollection, SampledPositionProperty, JulianDate, Cartographic, Sun, ShadowMode, Color, Ellipsoid, Matrix4, Transforms, Cesium3DTileset, Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import "cesium/Build/Cesium/Widgets/widgets.css";
import ViewerToolBar from './components/ViewerToolBar';
import NetworkSetup from './components/NetworkSetup.js';
import './css/main.css';

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

    function computeNewPoint(center, dx, dy, dz) {
        var offsetMatrix = Transforms.eastNorthUpToFixedFrame(center, Ellipsoid.WGS84, new Matrix4());
        var offsetPoint = Matrix4.multiplyByPoint(offsetMatrix, new Cartesian3(dx, dy, dz), new Cartesian3());
        return offsetPoint;
    }
    function plotPoint(newPoint) {
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
            if ((data.Settings.Airspace.Vertiports !== undefined) && (data.Settings.Airspace.Vertiports === 1)) {
                var dz0 = 0;
            } else {
                var dz0 = 0;
            }
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
        case "PAR":
            if ((data.Settings.Airspace.Vertiports !== undefined) && (data.Settings.Airspace.Vertiports === 1)) {
                var dz0 = 0;
            } else {
                var dz0 = 580;
            }
            var center = Cartesian3.fromDegrees(2.294670305890747, 48.85821322426023, dz0);
            break;
        case "HER":
            var dz0 = 300;
            var center = Cartesian3.fromDegrees(25.129820168413037, 35.333686242682596, dz0);
            break;
        case "ZHAW":
            var dz0 = 580;
            var center = Cartesian3.fromDegrees(8.726615248323863, 47.49776171780695, dz0);
        case "HK":
            var dz0 = 580;
            var center = Cartesian3.fromDegrees(114.173355, 22.296389, dz0); // Hong Kong
        case "LI":
            var dz0 = 0.0;
            var center = Cartesian3.fromDegrees(114.162559945072, 22.3158202017388, dz0); // Liechtenstein
    }
    plotPoint(center);
    const cesiumRed = Color.fromCssColorString('#C0282D');
    const cesiumBlue = Color.fromCssColorString('#076790');
    const cesiumGold = Color.fromCssColorString('#D59F0F');

    
    var randomNumberVerti = 0;
    ///////////////////////////////////////////////////////////////////////////////////////
    ViewSetting(center, NavigationOn);
    function ViewSetting(center, NavigationOn) {
        viewer.scene.globe.enableLighting = true; 
        viewer.shadows = true;
        viewer.scene.shadowMode = ShadowMode.ENABLED;
        viewer.shadowMap.maximumDistance = 5000.0;
        var initialPosition = computeNewPoint(center, 0, -10000, 20000);
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
            duration: 1,
        });
        var camera = viewer.camera;

        function onKeyDown(event) {
            keyState[event.key] = true;
            if ((event.key === 'ArrowUp' || event.key === 'ArrowDown' || event.key === 'ArrowLeft' || event.key === 'ArrowRight' || event.key === 'PageUp' || event.key === 'PageDown')) {
                event.preventDefault();
            }
            if ((event.key === 'N')) {
                try {
                    viewer.entities.removeAll();
                } catch (error) {
                    console.log(`Error loading
                  ${error}`);
                }
                isNetworkSetup = !isNetworkSetup;
                handleNetworkSetup(isNetworkSetup);
            }
            if ((event.key === 'P')) {
                isPedestrianSetup = !isPedestrianSetup;
                handlePedestrianSetup(isPedestrianSetup);
            }
            if ((event.key === 'h')) {
                pitch = initialOrientation.pitch;
                roll = initialOrientation.roll;
                yaw = initialOrientation.heading;
                height = initialPosition.height;
                camera.flyTo({
                    destination: initialPosition,
                    orientation: initialOrientation,
                });
                viewer.trackedEntity = undefined;
            }
            if ((event.key === 'V')) {
                viewer.trackedEntity = VertiportArray[randomNumberVerti];
                randomNumberVerti = randomNumberVerti + 1;
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
                VertiportArray[randomNumberVerti] = rotateEntity(VertiportArray[randomNumberVerti], 5);
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
        var newPointSE = computeNewPoint(centerPlotting, CubeDx / 2, -CubeDy / 2, 0); //(newPointSE);
        var newPointNE = computeNewPoint(centerPlotting, CubeDx / 2, CubeDy / 2, 0); //(newPointNE);
        var newPointSW = computeNewPoint(centerPlotting, -CubeDx / 2, -CubeDy / 2, 0); //(newPointSW);
        var newPointNW = computeNewPoint(centerPlotting, -CubeDx / 2, CubeDy / 2, 0); //(newPointNW);
        var newPointSEUP = computeNewPoint(centerPlotting, CubeDx / 2, -CubeDy / 2, CubeDz); //(newPointSEUP);
        var newPointNEUP = computeNewPoint(centerPlotting, CubeDx / 2, CubeDy / 2, CubeDz); //(newPointNEUP);
        var newPointSWUP = computeNewPoint(centerPlotting, -CubeDx / 2, -CubeDy / 2, CubeDz); //(newPointSWUP);
        var newPointNWUP = computeNewPoint(centerPlotting, -CubeDx / 2, CubeDy / 2, CubeDz); //(newPointNWUP);
        const scene = viewer.scene;
        var ellipsoid = scene.globe.ellipsoid;
        var cartographicNW = Cartographic.fromCartesian(newPointNW, ellipsoid);
        var cartographicNE = Cartographic.fromCartesian(newPointNE, ellipsoid);
        var cartographicSE = Cartographic.fromCartesian(newPointSE, ellipsoid);
        var cartographicSW = Cartographic.fromCartesian(newPointSW, ellipsoid);
        // var distance = Cartesian3.distance(newPointSE, newPointSEUP);
        // console.log("Distance between points: " + distance + " meters");
        const airspace = viewer.entities.add({
            name: nameStr,
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
                material: ColorStr,
                outline: true,
                outlineColor: outlineColorStr,
            },
            allowPicking: false,
        });
    }
    PlotCube(center, dx, dy, dz, dz0, dz1, 'Airspace', Color.BLACK.withAlpha(0.1), Color.BLACK);
    // if (data.Settings.Airspace.VTOL === 1) {
    //     PlotCube(center, dx, dy, dz1, dz0, 0, 'VTOLLayer', Color.RED.withAlpha(0.05), Color.RED);
    // }
    // try {
    //     data.Settings.Airspace.Layers.forEach((L, index) => {
    //         // console.log(computeNewPoint(center, L.center[1],L.center[2],L.center[3]),L.dx,L.dy,L.dz,dz0,dz1)
    //         PlotCube(computeNewPoint(center, L.center[0], L.center[1], L.center[2] - L.dz / 2), L.dx, L.dy, L.dz, dz0 + L.center[2] - L.dz / 2, 0, ['Layer ' + index], Color.CYAN.withAlpha(0.005), Color.CYAN.withAlpha(0.2))
    //     });
    // } catch (error) {
    //     console.log(`Error loading ${error}`);
    // }
    // try {
    //     data.Settings.Airspace.Regions.B.forEach((R, index) => {
    //         // console.log(computeNewPoint(center, L.center[1],L.center[2],L.center[3]),L.dx,L.dy,L.dz,dz0,dz1)
    //         if (R.ri === 1 || R.ri === 11 || R.ri === 21 || R.ri === 31) {
    //             PlotCube(computeNewPoint(center, R.center[0], R.center[1], R.center[2] - R.dz / 2), R.dx, R.dy, R.dz, dz0 + R.center[2] - R.dz / 2, 0, ['Region ' + R.ri], Color.CYAN.withAlpha(0.005), Color.RED.withAlpha(0.2))
    //         }
    //     });
    // } catch (error) {
    //     console.log(`Error loading ${error}`);
    // }
    // End Layers and Regions Settings
    ///////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////
    // Start Aircraft Motion
    async function generateFlightData(centerPoint, numSteps, dpx, dpy, dpz) {
        var flightData = [];
        var currentPosition = centerPoint;

        for (var i = 0; i < numSteps; i++) {
            flightData.push({
                longitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).longitude),
                latitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).latitude),
                height: Cartographic.fromCartesian(currentPosition).height
            });
            currentPosition = computeNewPoint(currentPosition, dpx, dpy, dpz);
        }
        return flightData;
    }

    function TestFlightsFunctions(center) {
        var numSteps = 75;
        var dx = 1500;
        var dy = 1500;
        var dz = 80;
        var dpx = 0;
        var dpy = 10;
        var dpz = 1;
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

    async function AddAircraftMotion(startSim, stopSim, timeStepInSeconds, AircraftIndex, flightData, AMI, statusData, tda, taa, rs, rd, vertical, entitiesArray, positionPropertyArray) {
        const startAircraft = new JulianDate.addSeconds(startSim, tda, new JulianDate());
        const stopAircraft = new JulianDate.addSeconds(startSim, taa, new JulianDate());
        const positionProperty = new SampledPositionProperty();
        const polylinePositions = [];
        const polylinePositionsDeg = [];
        // Load and draw waypoints
        for (let i = 0; i < flightData.length; i++) {
            const dataPoint = flightData[i];
            const time = JulianDate.addSeconds(startSim, i * timeStepInSeconds, new JulianDate());
            const position = Cartesian3.fromDegrees(dataPoint.longitude, dataPoint.latitude, dataPoint.height);
            positionProperty.addSample(time, position);
            polylinePositions.push(position);
            polylinePositionsDeg.push(position);
            const validTime = JulianDate.lessThanOrEquals(time, stop);
            const waypointEntity = viewer.entities.add({
                name: `Aircraft: ${AircraftIndex}, Waypoint: ${i}`,
                description: `Location: (${dataPoint.longitude}, ${dataPoint.latitude}, ${dataPoint.height})`,
                position: position,
                point: {
                    pixelSize: 2,
                    color: Color.DARKGRAY.withAlpha(0.5),
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
                material: Color.DARKGRAY.withAlpha(0.4),
                width: 1,
            },
            allowPicking: false,
        });
        pathEntity.availability = new TimeIntervalCollection([new TimeInterval({
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

        // Create completed path and planned path entities
        // Callback to update completed path positions
        const completedPathPositions = new CallbackProperty(() => {
            const currentTime = viewer.clock.currentTime;
            return polylinePositionsDeg.filter((_, index) => {
                const waypointTime = JulianDate.addSeconds(startSim, index * timeStepInSeconds, new JulianDate());
                return JulianDate.lessThanOrEquals(waypointTime, currentTime);
            });
        }, false);

        // Callback to update planned path positions
        const plannedPathPositions = new CallbackProperty(() => {
            const currentTime = viewer.clock.currentTime;
            return polylinePositionsDeg.filter((_, index) => {
                const waypointTime = JulianDate.addSeconds(startSim, index * timeStepInSeconds, new JulianDate());
                return JulianDate.greaterThan(waypointTime, currentTime);
            });
        }, false);

        // Add completed path entity
        const completed_path_entity = viewer.entities.add({
            polyline: {
                positions: completedPathPositions,
                material: Color.DARKBLUE.withAlpha(0.4),
                width: 1,
            },
            allowPicking: false,
        });

        completed_path_entity.availability = new TimeIntervalCollection([new TimeInterval({
            start: startAircraft,
            stop: stopAircraft
        })]);

        // Add planned path entity
        const planned_path_entity = viewer.entities.add({
            polyline: {
                positions: plannedPathPositions,
                material: new PolylineDashMaterialProperty({
                    color: Color.DARKRED.withAlpha(0.4),
                    dashLength: 8.0,
                }),
                width: 1,
            },
            allowPicking: false,
        });

        planned_path_entity.availability = new TimeIntervalCollection([new TimeInterval({
            start: startAircraft,
            stop: stopAircraft
        })]);

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
                    uri: AircraftURL,
                    scale: AircraftURLScale
                },
                path: new PathGraphics({ width: 0.2 }),
                orientation: calculateOrientation(positionProperty, dz1), // Use a callback for orientation // TODO: FIX ISSUE
                // orientation: new VelocityOrientationProperty(positionProperty), // TODO: FIX ISSUE
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

        // KNOWN ISSUES WORKING FOR NYC ONLY TODO: Fix Function
        function calculateOrientation(positionProperty) {
            const velocityOrientation = new VelocityOrientationProperty(positionProperty, Ellipsoid.WGS84);

            return new CallbackProperty(function (time, result) {
                const currentOrientation = velocityOrientation.getValue(time);
                if (!currentOrientation) {
                    return result;
                }
                const hpr = HeadingPitchRoll.fromQuaternion(currentOrientation);
                const maxPitch = CesiumMath.toRadians(10);
                const minPitch = CesiumMath.toRadians(-10);
                const maxRoll = CesiumMath.toRadians(2);
                const minRoll = CesiumMath.toRadians(-2);
                hpr.pitch = CesiumMath.clamp(hpr.pitch, minPitch, maxPitch);
                hpr.roll = CesiumMath.clamp(hpr.roll, minRoll, maxRoll);
                return Transforms.headingPitchRollQuaternion(
                    positionProperty.getValue(time),
                    hpr,
                    Ellipsoid.WGS84,
                );
            }, false);
        }

        entitiesArray, positionPropertyArray = loadModel(positionProperty, entitiesArray, positionPropertyArray, AMI);
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    // Start Vertiport setting
    var VertiportArray = [];
    async function AddVertiport(VertiportIndex, FunVertiportLocation, FunheadingPositionRoll, FunfixedFrameTransform, VertiportArray) {
        try {
            const vertiport_size = 10;
            const vertiport_obj_size = 0.5 * vertiport_size / 15;
            const adjusted_FunVertiportLocation = computeNewPoint(FunVertiportLocation, 0, 0, 2);
            const entityVertiport = viewer.entities.add({
                name: "Vertiport " + VertiportIndex,
                position: adjusted_FunVertiportLocation,
                model: {
                    uri: "/OneVertiport.glb",
                    scale: vertiport_obj_size,
                },
                orientation: Cesium.Transforms.headingPitchRollQuaternion(
                    adjusted_FunVertiportLocation,
                    FunheadingPositionRoll,
                    Ellipsoid.WGS84,
                    FunfixedFrameTransform
                )
            });
            VertiportArray.push(entityVertiport);
            const VertiPortSphereEntityB = viewer.entities.add({
                name: 'Vertiport ' + VertiportIndex + ' - Safety Space',
                description: ``,
                position: computeNewPoint(adjusted_FunVertiportLocation, 0, 0, 0),
                ellipsoid: {
                    radii: new Cartesian3(vertiport_size, vertiport_size, vertiport_size),
                    material: Color.RED.withAlpha(0.1),
                    outline: true,
                    outlineColor: Color.BLACK.withAlpha(0.2),
                },
                allowPicking: false,
            });
            const oVEntity = viewer.entities.add({
                name: "Vertiport " + VertiportIndex,
                position: adjusted_FunVertiportLocation,
                point: {
                    pixelSize: 10,
                    color: Color.RED.withAlpha(0.1),
                    markerSymbol: 'X'
                },
                allowPicking: false,
            });
            console.log(VertiportArray)
            console.log('Added Vertiport to array')
            return VertiportArray;
        } catch (error) {
            console.log(`Failed to load model. ${error}`);
        }
    }

    ////////////////////////////////////////////
    // Add Vertiports.
    var scene = viewer.scene;
    if (!scene.pickPositionSupported) {
        window.alert("This browser does not support pickPosition.");
    }
    if (!scene.sampleHeightSupported) {
        window.alert("This browser does not support sampleHeight.");
    }
    var ellipsoid = scene.globe.ellipsoid;
    var handler = new Cesium.ScreenSpaceEventHandler(scene.canvas);
    var isNetworkSetup = false; //document.getElementById('showNetworkSetup').checked;

    function handleNetworkSetup(isNetworkSetup) {
        if (isNetworkSetup) {
            const labelEntity = viewer.entities.add({
                label: {
                    show: false,
                    showBackground: true,
                    font: "14px Latin Modern",
                    horizontalOrigin: Cesium.HorizontalOrigin.LEFT,
                    verticalOrigin: Cesium.VerticalOrigin.TOP,
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
                            const longitudeString = CesiumMath.toDegrees(
                                cartographic.longitude
                            ).toFixed(2);
                            const latitudeString = CesiumMath.toDegrees(
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
                const longitudeDeg = CesiumMath.toDegrees(lonLat.longitude);
                const latitudeDeg = CesiumMath.toDegrees(lonLat.latitude);
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

            function calculateNEUDistances(center, VertiportLocation) {
                const transformMatrix = Cesium.Transforms.eastNorthUpToFixedFrame(center);
                const inverseTransformMatrix = Cesium.Matrix4.inverse(transformMatrix, new Cesium.Matrix4());

                const localPosition = new Cesium.Cartesian3();
                Cesium.Matrix4.multiplyByPoint(inverseTransformMatrix, VertiportLocation, localPosition);

                return {
                    north: localPosition.y,
                    east: localPosition.x,
                    up: localPosition.z
                };
            }
            const VertiportData = [];
            var VertiportIndex = 0;

            function addObjectAndSaveData(cartesian, longitudeDeg, latitudeDeg, heightDeg, VertiportArray) {
                try {
                    const VertiportLocation = cartesian;
                    const headingPositionRollVertiport = new Cesium.HeadingPitchRoll();
                    const fixedFrameTransformVertiport = Cesium.Transforms.localFrameToFixedFrameGenerator("north", "west");
                    VertiportArray = AddVertiport(VertiportIndex, VertiportLocation, headingPositionRollVertiport, fixedFrameTransformVertiport, VertiportArray);
                    const neuDistances = calculateNEUDistances(center, VertiportLocation);
                    const VertiportInfo = {
                        index: VertiportIndex,
                        longitude: longitudeDeg,
                        latitude: latitudeDeg,
                        height: heightDeg,
                        cartesian: {
                            x: cartesian.x,
                            y: cartesian.y,
                            z: cartesian.z
                        },
                        neuDistances: neuDistances,
                    };
                    VertiportData.push(VertiportInfo);
                    console.log('Added Vertiport at ' + longitudeDeg, latitudeDeg, heightDeg);
                    console.log('Distance of Vertiport from cetner ' + neuDistances.north, neuDistances.east, neuDistances.up);

                    // Send Vertiport data to the server
                    saveVertiportData(VertiportData);
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
                    body: JSON.stringify({ VertiportData: data }),
                })
                    .then(response => response.json())
                    .then(data => console.log('Server response:', data))
                    .catch(error => console.error('Error:', error));
            }
        } else {
            handler.setInputAction(function (movement) {
            }, Cesium.ScreenSpaceEventType.MOUSE_MOVE);
            handler.setInputAction(function (event) {
                console.log('Network Setup is off')
            }, Cesium.ScreenSpaceEventType.LEFT_DOUBLE_CLICK);
        }
    }

    // Function to rotate a specific entity
    function rotateEntity(entityRotated, angleOffset) {
        console.log(entityRotated)
        console.log('Rotating in' + angleOffset + 'degrees')
        const currentOrientation = entityRotated.orientation.getValue(Cesium.JulianDate.now());
        const rotation = Cesium.Matrix3.fromQuaternion(currentOrientation);
        const rotationMatrix = Cesium.Matrix3.fromRotationZ(CesiumMath.toRadians(angleOffset));
        const newRotation = Cesium.Matrix3.multiply(rotation, rotationMatrix, new Cesium.Matrix3());
        entityRotated.orientation = Cesium.Quaternion.fromRotationMatrix(newRotation);
        return entityRotated;
    }
    if ((data.Settings.Airspace.Vertiports !== undefined) && (data.Settings.Airspace.Vertiports === 1)) {
        var FetchVertiportFileName = '/FixedVertiportsSettings_V2_NYC.json';
        switch (city) {
            case "NYC":
                var FetchVertiportFileName = '/FixedVertiportsSettings_V2_NYC.json';
                break;
            case "PAR":
                var FetchVertiportFileName = '/FixedVertiportsSettings_V1_PAR.json';
                break;
            case "SF":
                var FetchVertiportFileName = '/FixedVertiportsSettings_V1_SF.json';
                break;
            case "HK":
                var FetchVertiportFileName = '/FixedVertiportsSettings_V1_HK.json';
                break;
            case "LI":
                var FetchVertiportFileName = '/FixedVertiportsSettings_V2_LI.json';
                break;
        }

        fetch(FetchVertiportFileName)
            .then(response => response.json())
            .then(data => {
                data.forEach(Vertiport => {
                    const FunVertiportLocation = Cesium.Cartesian3.fromDegrees(
                        Vertiport.longitude,
                        Vertiport.latitude,
                        Vertiport.height
                    );
                    const headingPositionRoll = new Cesium.HeadingPitchRoll();
                    const fixedFrameTransform = Cesium.Transforms.localFrameToFixedFrameGenerator("north", "west");
                    AddVertiport(Vertiport.index, FunVertiportLocation, headingPositionRoll, fixedFrameTransform, VertiportArray);
                });
            })
            .catch(error => console.error('Error loading fixed Vertiport settings:', error));
    }
    // End Vertiport setting
    ///////////////////////////////////////////////////////////////////////////////////////

    //async function main() {
    // Add Aircraft Data from the simulation
    const dtS = data.SimInfo.dtS;
    const tf = data.SimInfo.tf / dtS;
    const timeStepInSeconds = 10 * dtS;
    const dt = timeStepInSeconds / dtS;
    const totalSeconds = data.SimInfo.tf;
    const currentTime = Cesium.JulianDate.now();
    const startSim = currentTime;
    const stopSim = JulianDate.addSeconds(startSim, totalSeconds, new JulianDate());
    viewer.clock.startTime = startSim.clone();
    viewer.clock.stopTime = stopSim.clone();
    viewer.clock.currentTime = startSim.clone();
    viewer.timeline.zoomTo(startSim, stopSim);
    viewer.clock.multiplier = 1;
    viewer.clock.shouldAnimate = false;
    viewer.clock.clockRange = ClockRange.CLAMPED;
    viewer.clock.clockStep = ClockStep.SYSTEM_CLOCK_MULTIPLIER;
    var entitiesArray = [];
    var positionPropertyArray = [];

    data.ObjAircraft.forEach((ObjAircraft, index) => {
        if ((index > 0) & (index < 250)) { // TODO: Enhance to be unlimited by agents (currently 250)
            const trajectoryPositions = [];
            for (let i = 0; i < ObjAircraft.x.length; i += dt) {
                const currentPosition = computeNewPoint(center, ObjAircraft.x[i], ObjAircraft.y[i], ObjAircraft.z[i]);
                trajectoryPositions.push({
                    longitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).longitude),
                    latitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).latitude),
                    height: Cartographic.fromCartesian(currentPosition).height
                });
            }
            AddAircraftMotion(startSim, stopSim, timeStepInSeconds, index + 1, trajectoryPositions, ObjAircraft.AMI, ObjAircraft.status, ObjAircraft.tda, ObjAircraft.taa, ObjAircraft.rs, ObjAircraft.rd, 0, entitiesArray, positionPropertyArray);
        }
    });
    // Cesium Main End
    //};
}