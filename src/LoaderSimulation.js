import { IonResource, ClockStep, ClockRange, HeadingPitchRoll, VelocityOrientationProperty, PathGraphics, DistanceDisplayCondition, CallbackProperty, TimeInterval, TimeIntervalCollection, SampledPositionProperty, JulianDate, Cartographic, Sun, ShadowMode, Color, Ellipsoid, Matrix4, Transforms, Cesium3DTileset, Cartesian3, createOsmBuildingsAsync, Ion, Math as CesiumMath, Terrain, Viewer } from 'cesium';
import "cesium/Build/Cesium/Widgets/widgets.css";
// =================================================================================================================================================
// Cesium Simulation
// =================================================================================================================================================

export async function LoadSimulation(viewer, data) {
    try {
        viewer.entities.removeAll();
    } catch (error) {
        console.log(`Error loading
      ${error}`);
    }

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
        viewer.entities.add({
            name: `Point`,
            description: `Location: (${newPoint.x}, ${newPoint.y}, ${newPoint.z})`,
            position: newPoint,
            point: {
                pixelSize: 5,
                color: Color.BLACK,
                outlineColor: Color.WHITE,
                outlineWidth: 1,
                allowPicking: false,
            },
        });
        return undefined;
    }
    ///////////////////////////////////////////////////////////////////////////////////////
    // Center point
    var dx = data[0].dx;
    var dy = data[0].dy;
    var dz = data[0].dz;
    var as;
    if (data[0].as !== undefined) {
        as = data[0].as;
    } else {
        as = 2;
    }
    var dz0 = 480;
    // var center = Cartesian3.fromDegrees(-122.3816, 37.6191, dz0); // SF
    // var center = Cartesian3.fromDegrees(35.045628640781565, 32.77278697558125,  dz0); // NESHER
    // var center = Cartesian3.fromDegrees(35.01178943640926, 32.76765420453765,  dz0); // HAIFA
    // var center = Cartesian3.fromDegrees(35.29755740551859, 32.702149095841264, dz0); // NAZ
    var center = Cartesian3.fromDegrees(-73.98435971601633, 40.75171803897241, dz0); // NYC
    ///////////////////////////////////////////////////////////////////////////////////////
    function ViewSetting(center) {
        viewer.scene.globe.enableLighting = true; // Enable lighting for the sun and shadows
        viewer.shadows = true; // Enable shadows

        // Set shadow mode (for example, to have both terrain and 3D models cast and receive shadows):
        viewer.scene.shadowMode = ShadowMode.ENABLED;

        // You can also specify how detailed the shadows should be (higher quality may impact performance):
        viewer.shadowMap.maximumDistance = 5000.0; // Maximum shadow distance in meters

        // Create a light source for the sun
        var sunLight = new Sun();

        // Set the light source direction (optional, the default is the sun's position)
        sunLight.direction = Cartesian3.normalize(new Cartesian3(0.5, 0.5, 0.5), new Cartesian3());

        // Add the light source to the scene
        viewer.scene.sun = sunLight;
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
        // Add event listeners to track key state
        window.addEventListener('keydown', function (event) {
            keyState[event.key] = true;
            if (event.key === 'ArrowUp' || event.key === 'ArrowDown' || event.key === 'ArrowLeft' || event.key === 'ArrowRight' || event.key === 'PageUp' || event.key === 'PageDown') {
                event.preventDefault(); // Prevent scrolling when arrow keys are pressed
            }
            if (event.key === 'h') {
                // Reset camera to initial position and orientation
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
            if (event.key === 'r') {
                var randomNumber = Math.floor(Math.random() * entitiesArray.length);
                var FindEntity = 1;
                while (FindEntity) {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        viewer.trackedEntity = entitiesArray[randomNumber];
                        FindEntity = 0;
                    } else {
                        randomNumber = Math.floor(Math.random() * entitiesArray.length);
                    }
                }
            }
            if (event.key === 'f') {
                var randomNumber = Math.floor(Math.random() * entitiesArray.length);
                var FindEntity = 1;
                while (FindEntity) {
                    if ((viewer.clock.currentTime > entitiesArray[randomNumber].availability.start) && (viewer.clock.currentTime < entitiesArray[randomNumber].availability.stop)) {
                        viewer.zoomTo(entitiesArray[randomNumber]);
                        FindEntity = 0;
                    } else {
                        randomNumber = Math.floor(Math.random() * entitiesArray.length);
                    }
                }
            }

        });
        window.addEventListener('keyup', function (event) {
            keyState[event.key] = false;
        });
        // Create a function to handle movement
        function handleMovement() {
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
        // Start handling movement
        handleMovement();
    }
    ViewSetting(center);
    // End view settings
    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    // var as = 2;
    if (as == 1) {
        function PlotAirspace(center) {
            //var newPointSEGround = computeNewPoint(center, dx / 2, -dy / 2, 0); plotPoint(newPointSEGround);
            //var newPointNEGround = computeNewPoint(center, dx / 2, dy / 2, 0); plotPoint(newPointNEGround);
            //var newPointSWGround = computeNewPoint(center, -dx / 2, -dy / 2, 0); plotPoint(newPointSWGround);
            //var newPointNWGround = computeNewPoint(center, -dx / 2, dy / 2, 0); plotPoint(newPointNWGround);
            const centerPlotting = computeNewPoint(center, 0, 0, 0); // For Subset Simulation
            plotPoint(centerPlotting);
            var newPointSE = computeNewPoint(centerPlotting, dx / 2, -dy / 2, 0); plotPoint(newPointSE);
            var newPointNE = computeNewPoint(centerPlotting, dx / 2, dy / 2, 0); plotPoint(newPointNE);
            var newPointSW = computeNewPoint(centerPlotting, -dx / 2, -dy / 2, 0); plotPoint(newPointSW);
            var newPointNW = computeNewPoint(centerPlotting, -dx / 2, dy / 2, 0); plotPoint(newPointNW);
            var newPointSEUP = computeNewPoint(centerPlotting, dx / 2, -dy / 2, dz); plotPoint(newPointSEUP);
            var newPointNEUP = computeNewPoint(centerPlotting, dx / 2, dy / 2, dz); plotPoint(newPointNEUP);
            var newPointSWUP = computeNewPoint(centerPlotting, -dx / 2, -dy / 2, dz); plotPoint(newPointSWUP);
            var newPointNWUP = computeNewPoint(centerPlotting, -dx / 2, dy / 2, dz); plotPoint(newPointNWUP);
            //var distance = Cartesian3.distance(center, computeNewPoint(center, 1500, 0, 0));
            //console.log("Distance between points: " + distance + " meters");
            // Convert Cartesian3 coordinates to Cartographic coordinates
            var cartographicNW = Cartographic.fromCartesian(newPointNW);
            var cartographicNE = Cartographic.fromCartesian(newPointNE);
            var cartographicSE = Cartographic.fromCartesian(newPointSE);
            var cartographicSW = Cartographic.fromCartesian(newPointSW);
            // Create a polygon entity connecting the four points
            const airspace = viewer.entities.add({
                name: `Airspace`,
                description: ``,
                polygon: {
                    hierarchy: Cartesian3.fromDegreesArray([
                        CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                        CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                        CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                        CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                    ]),
                    height: dz0, // Set the minimum height to 40 meters AGL
                    extrudedHeight: dz0 + dz, // Set the maximum height to 120 meters AGL
                    material: Color.CYAN.withAlpha(0.1),
                    outline: true,
                    outlineColor: Color.CYAN,
                    allowPicking: false,
                },
            });
            //viewer.zoomTo(airspace);
        }
        PlotAirspace(center);

    } else if(as == 2) {
        // Plot Airspace Border  
        function PlotAirspace(center) {
            var newPointSEGround = computeNewPoint(center, dx / 2, -dy / 2, 0); plotPoint(newPointSEGround);
            var newPointNEGround = computeNewPoint(center, dx / 2, dy / 2, 0); plotPoint(newPointNEGround);
            var newPointSWGround = computeNewPoint(center, -dx / 2, -dy / 2, 0); plotPoint(newPointSWGround);
            var newPointNWGround = computeNewPoint(center, -dx / 2, dy / 2, 0); plotPoint(newPointNWGround);
            const centerPlotting = computeNewPoint(center, 0, 0, 40); // For Subset Simulation
            plotPoint(centerPlotting);
            var newPointSE = computeNewPoint(centerPlotting, dx / 2, -dy / 2, 0); plotPoint(newPointSE);
            var newPointNE = computeNewPoint(centerPlotting, dx / 2, dy / 2, 0); plotPoint(newPointNE);
            var newPointSW = computeNewPoint(centerPlotting, -dx / 2, -dy / 2, 0); plotPoint(newPointSW);
            var newPointNW = computeNewPoint(centerPlotting, -dx / 2, dy / 2, 0); plotPoint(newPointNW);
            var newPointSEUP = computeNewPoint(centerPlotting, dx / 2, -dy / 2, dz); plotPoint(newPointSEUP);
            var newPointNEUP = computeNewPoint(centerPlotting, dx / 2, dy / 2, dz); plotPoint(newPointNEUP);
            var newPointSWUP = computeNewPoint(centerPlotting, -dx / 2, -dy / 2, dz); plotPoint(newPointSWUP);
            var newPointNWUP = computeNewPoint(centerPlotting, -dx / 2, dy / 2, dz); plotPoint(newPointNWUP);
            //var distance = Cartesian3.distance(center, computeNewPoint(center, 1500, 0, 0));
            //console.log("Distance between points: " + distance + " meters");
            // Convert Cartesian3 coordinates to Cartographic coordinates
            var cartographicNW = Cartographic.fromCartesian(newPointNW);
            var cartographicNE = Cartographic.fromCartesian(newPointNE);
            var cartographicSE = Cartographic.fromCartesian(newPointSE);
            var cartographicSW = Cartographic.fromCartesian(newPointSW);
            // Create a polygon entity connecting the four points
            const airspace = viewer.entities.add({
                name: `Airspace`,
                description: ``,
                polygon: {
                    hierarchy: Cartesian3.fromDegreesArray([
                        CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                        CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                        CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                        CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                    ]),
                    height: dz0 + 40, // Set the minimum height to 40 meters AGL
                    extrudedHeight: dz0 + 40 + dz, // Set the maximum height to 120 meters AGL
                    material: Color.CYAN.withAlpha(0.05),
                    outline: true,
                    outlineColor: Color.CYAN,
                    allowPicking: false,
                },
            });
            //viewer.zoomTo(airspace);
        }
        PlotAirspace(center);

        function PlotAirspaceLayers(center) {
            const centerPlotting = computeNewPoint(center, 0, 0, 40); // For Subset Simulation
            var newPointSE = computeNewPoint(centerPlotting, dx / 2, -dy / 2, 0);
            var newPointNE = computeNewPoint(centerPlotting, dx / 2, dy / 2, 0);
            var newPointSW = computeNewPoint(centerPlotting, -dx / 2, -dy / 2, 0);
            var newPointNW = computeNewPoint(centerPlotting, -dx / 2, dy / 2, 0);
            var newPointSEUP = computeNewPoint(centerPlotting, dx / 2, -dy / 2, dz);
            var newPointNEUP = computeNewPoint(centerPlotting, dx / 2, dy / 2, dz);
            var newPointSWUP = computeNewPoint(centerPlotting, -dx / 2, -dy / 2, dz);
            var newPointNWUP = computeNewPoint(centerPlotting, -dx / 2, dy / 2, dz);
            //var distance = Cartesian3.distance(center, computeNewPoint(center, 1500, 0, 0));
            //console.log("Distance between points: " + distance + " meters");
            // Convert Cartesian3 coordinates to Cartographic coordinates
            var cartographicNW = Cartographic.fromCartesian(newPointNW);
            var cartographicNE = Cartographic.fromCartesian(newPointNE);
            var cartographicSE = Cartographic.fromCartesian(newPointSE);
            var cartographicSW = Cartographic.fromCartesian(newPointSW);
            // Create a polygon entity connecting the four points
            const airspaceL0 = viewer.entities.add({
                name: `Layer 0`,
                description: ``,
                polygon: {
                    hierarchy: Cartesian3.fromDegreesArray([
                        CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                        CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                        CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                        CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                    ]),
                    height: dz0, // Set the minimum height to 40 meters AGL
                    extrudedHeight: dz0 + 40, // Set the maximum height to 120 meters AGL
                    material: Color.BLACK.withAlpha(0.1),
                    outline: true,
                    outlineColor: Color.BLACK,
                    allowPicking: false,
                },
            });
            const airspaceL1 = viewer.entities.add({
                name: `Layer 0`,
                description: ``,
                polygon: {
                    hierarchy: Cartesian3.fromDegreesArray([
                        CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                        CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                        CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                        CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                    ]),
                    height: dz0 + 40, // Set the minimum height to 40 meters AGL
                    extrudedHeight: dz0 + 40 + dz / 2, // Set the maximum height to 120 meters AGL
                    material: Color.YELLOW.withAlpha(0.1),
                    outline: true,
                    outlineColor: Color.BLACK,
                    allowPicking: false,
                },
            });
            const airspaceL2 = viewer.entities.add({
                name: `Layer 0`,
                description: ``,
                polygon: {
                    hierarchy: Cartesian3.fromDegreesArray([
                        CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                        CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                        CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                        CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                    ]),
                    height: dz0 + 40 + dz / 2, // Set the minimum height to 40 meters AGL
                    extrudedHeight: dz0 + 40 + dz, // Set the maximum height to 120 meters AGL
                    material: Color.BLACK.withAlpha(0.1),
                    outline: true,
                    outlineColor: Color.BLACK,
                    allowPicking: false,
                },
            });
            //viewer.zoomTo(airspace);
        }
        PlotAirspaceLayers(center);

        function PlotAirspaceCentersRegions(center) {
            const centerPlotting = computeNewPoint(center, 0, 0, 40); // For Subset Simulation
            var newPointSE = computeNewPoint(centerPlotting, dx / 6, -dy / 6, 0);
            var newPointNE = computeNewPoint(centerPlotting, dx / 6, dy / 6, 0);
            var newPointSW = computeNewPoint(centerPlotting, -dx / 6, -dy / 6, 0);
            var newPointNW = computeNewPoint(centerPlotting, -dx / 6, dy / 6, 0);
            var newPointSEUP = computeNewPoint(centerPlotting, dx / 6, -dy / 6, dz);
            var newPointNEUP = computeNewPoint(centerPlotting, dx / 6, dy / 6, dz);
            var newPointSWUP = computeNewPoint(centerPlotting, -dx / 6, -dy / 6, dz);
            var newPointNWUP = computeNewPoint(centerPlotting, -dx / 6, dy / 6, dz);
            //var distance = Cartesian3.distance(center, computeNewPoint(center, 1500, 0, 0));
            //console.log("Distance between points: " + distance + " meters");
            // Convert Cartesian3 coordinates to Cartographic coordinates
            var cartographicNW = Cartographic.fromCartesian(newPointNW);
            var cartographicNE = Cartographic.fromCartesian(newPointNE);
            var cartographicSE = Cartographic.fromCartesian(newPointSE);
            var cartographicSW = Cartographic.fromCartesian(newPointSW);
            // Create a polygon entity connecting the four points
            const airspaceL0 = viewer.entities.add({
                name: `Layer 0`,
                description: ``,
                polygon: {
                    hierarchy: Cartesian3.fromDegreesArray([
                        CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                        CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                        CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                        CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                    ]),
                    height: dz0, // Set the minimum height to 40 meters AGL
                    extrudedHeight: dz0 + 40, // Set the maximum height to 120 meters AGL
                    material: Color.BLACK.withAlpha(0.1),
                    outline: true,
                    outlineColor: Color.BLACK,
                    allowPicking: false,
                },
            });
            const airspaceL1 = viewer.entities.add({
                name: `Layer 0`,
                description: ``,
                polygon: {
                    hierarchy: Cartesian3.fromDegreesArray([
                        CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                        CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                        CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                        CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                    ]),
                    height: dz0 + 40, // Set the minimum height to 40 meters AGL
                    extrudedHeight: dz0 + 40 + dz / 2, // Set the maximum height to 120 meters AGL
                    material: Color.RED.withAlpha(0.1),
                    outline: true,
                    outlineColor: Color.BLACK,
                    allowPicking: false,
                },
            });
            const airspaceL2 = viewer.entities.add({
                name: `Layer 0`,
                description: ``,
                polygon: {
                    hierarchy: Cartesian3.fromDegreesArray([
                        CesiumMath.toDegrees(cartographicNW.longitude), CesiumMath.toDegrees(cartographicNW.latitude),
                        CesiumMath.toDegrees(cartographicNE.longitude), CesiumMath.toDegrees(cartographicNE.latitude),
                        CesiumMath.toDegrees(cartographicSE.longitude), CesiumMath.toDegrees(cartographicSE.latitude),
                        CesiumMath.toDegrees(cartographicSW.longitude), CesiumMath.toDegrees(cartographicSW.latitude),
                    ]),
                    height: dz0 + 40 + dz / 2, // Set the minimum height to 40 meters AGL
                    extrudedHeight: dz0 + 40 + dz, // Set the maximum height to 120 meters AGL
                    material: Color.BLACK.withAlpha(0.1),
                    outline: true,
                    outlineColor: Color.BLACK,
                    allowPicking: false,
                },
            });
            //viewer.zoomTo(airspace);
        }
        PlotAirspaceCentersRegions(center);
        // End airspace plotting
    } else {

    }
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

    async function AddAircraftMotion(startSim, stopSim, timeStepInSeconds, AircraftIndex, flightData, statusData, tda, taa, rs, rd, vertical, entitiesArray) {
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
        async function loadModel(positionProperty, entitiesArray) {
            const airplaneUri = await IonResource.fromAssetId(2321473);
            const airplaneEntity = viewer.entities.add({
                name: `Aircraft: ${AircraftIndex}, Model`,
                description: ``,
                position: positionProperty,
                model: {
                    uri: airplaneUri,
                    scale: 30.0
                },
                path: new PathGraphics({ width: 0.2 }),
                // orientation: vertical === 0 ? new VelocityOrientationProperty(positionProperty) : undefined,
                orientation: calculateOrientation(positionProperty), // Use a callback for orientation
                allowPicking: true,
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
            return entitiesArray;
        }

        entitiesArray = loadModel(positionProperty, entitiesArray);

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


    //async function main() {
    // Add Aircraft Data from the simulation
    const dtS = data[0].dtS;
    const tf = data[0].tf / dtS;
    const timeStepInSeconds = 10 * dtS; // for objects dt Plotting, every 00 seconds.
    const dt = timeStepInSeconds / dtS; // for importing.
    const totalSeconds = data[0].tf;//timeStepInSeconds * (tf - 1);
    const startSim = JulianDate.fromIso8601("1903-12-17T10:35:00Z");
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

    data.forEach((ObjAircraft, index) => {
        if ((index > 0) & (index < 100)) {
            //const startAircraft = new JulianDate.addSeconds(startSim, ObjAircraft.ObjAircraft.tda, new JulianDate());
            //const stopAircraft = new JulianDate.addSeconds(startSim, ObjAircraft.ObjAircraft.taa, new JulianDate());
            const trajectoryPositions = [];
            for (let i = 0; i < ObjAircraft.ObjAircraft.x.length; i += dt) {
                const currentPosition = computeNewPoint(center, ObjAircraft.ObjAircraft.x[i], ObjAircraft.ObjAircraft.y[i], ObjAircraft.ObjAircraft.z[i]);
                trajectoryPositions.push({
                    longitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).longitude),
                    latitude: CesiumMath.toDegrees(Cartographic.fromCartesian(currentPosition).latitude),
                    height: Cartographic.fromCartesian(currentPosition).height
                });
            } // IF INDEX END
            AddAircraftMotion(startSim, stopSim, timeStepInSeconds, index + 1, trajectoryPositions, ObjAircraft.ObjAircraft.status, ObjAircraft.ObjAircraft.tda, ObjAircraft.ObjAircraft.taa, ObjAircraft.ObjAircraft.rs, ObjAircraft.ObjAircraft.rd, 0, entitiesArray);
        }
    });

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