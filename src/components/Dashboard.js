import React, { useState, useEffect } from 'react';
import axios from 'axios';

import Analytics from './Analytics';
import Settings from './Settings';
import { LoadSimulation } from '.././LoaderSimulation';
import { viewer } from '.././index';


const Dashboard = () => {
    // =======================================================================================
    // MATLAB Call ===========================================================================
    // ============ MATLAB Code =========================


    const runMatlabCode = async () => {
        try {
            const response = await fetch('/api/run_matlab_code', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({}),
            });

            if (!response.ok) {
                throw new Error('Network response was not ok');
            }

            const data = await response.json();
            console.log('MATLAB Result:', data.result);
            // Update the DOM with the result
            document.getElementById('result-container').innerHTML = 'MATLAB Result: ' + data.result;
        } catch (error) {
            console.error('Error:', error);
            // Update the DOM with the error
            document.getElementById('result-container').innerHTML = 'Error: ' + error.message;
        }
    };

    // =======================================================================================
    const [jsonFiles, setJsonFiles] = useState([]);

    const fetchJsonFiles = async () => {
        try {
            const response = await axios.get('/api/getJsonFiles');
            setJsonFiles(response.data.files);
        } catch (error) {
            console.error('Error fetching JSON files:', error);
        }
    };

    useEffect(() => {
        fetchJsonFiles();
    }, []);

    const handleAddFile = async () => {
        // Logic to add a new file to the folder
        // After adding the file, trigger a re-fetch of the file list
        await fetchJsonFiles();
    };

    // GUI Handles ===========================================================================
    // Handle file dropdown change
    const handleDropdownChange = (event) => {
        const selectedOption = event.target.value;
        setSelectedFile(selectedOption);
    };
    // Handle file submission (if needed)
    const handleFileChange = (event) => {
        // Your file submission logic here if necessary
    };
    // Handle file submission (if needed)
    const handleSubmit = (event) => {
        event.preventDefault();
        // Your file submission logic here if necessary
    };
    // =======================================================================================
    // Run and Load Simulation Handles =======================================================
    const [selectedFile, setSelectedFile] = useState("/Samples/SimOutput_ObjAircraft_Default.json");
    useEffect(() => {
        // Fetch initial data when the component mounts
        const initialSelectedFile = selectedFile;
        fetch(initialSelectedFile)
            .then(response => response.json())
            .then(data => {
                // Call your function with the fetched data
                LoadSimulation(viewer, data);
            })
            .catch(error => {
                console.error('Error fetching data:', error);
            });
    }, [selectedFile]);  // Dependency array ensures this effect runs when selectedFile changes


    // =======================================================================================
    // Groups ================================================================================
    const [isContentVisible, setIsContentVisible] = useState(false);

    const handleToggleContent = () => {
        setIsContentVisible(!isContentVisible);
    };
    // =======================================================================================
    // GUI ===================================================================================
    return (
        <div className="container mt-5">
            <h3>Dashboard</h3>
            <b><center><p className="mt-3">Viewer Selected File: {selectedFile}</p></center></b>
            <div className="form-group text-center">
                <select className="form-select" id="filenameDropdown" onChange={handleDropdownChange} value={selectedFile}>
                    <option value={selectedFile}>
                        Select a Simulation Sample
                    </option>
                    <option value="/Samples/SimOutput_ObjAircraft_Default.json">Default</option>
                    <option value="/Samples/SimOutput_ObjAircraft_VTOL.json">VTOL</option>
                    <option value="/Samples/SimOutput_ObjAircraft_Subset.json">Subset</option>
                    <option value="/Samples/SimOutput_ObjAircraft_Control.json">VTOL Control</option>
                    <option value="/Samples/SimOutput_ObjAircraft_Congestion_Control.json">VTOL Control - OSC</option>
                </select>
            </div>
            <br />

            <Settings />

            <button
                className="btn btn-success btn-lg btn-block mb-3"
                onClick={runMatlabCode}
            >
                Run New Simulation
            </button>

            <div id="result-container" className="mt-3"></div>

            <div id="loading-bar" className="progress mt-3" style={{ display: 'none' }}>
                <div
                    id="loading-bar-inner"
                    className="progress-bar progress-bar-striped progress-bar-animated"
                    role="progressbar"
                    aria-valuemin="0"
                    aria-valuemax="100"
                    style={{ width: '0%' }}
                ></div>
            </div>

            <button
                className="btn btn-primary btn-lg btn-block"
                onClick={handleAddFile}
            >
                Add Simulation Data to Server
            </button>


            <select className="form-select" id="jsonDropdown" onChange={handleDropdownChange} value={selectedFile}>
                <option value={selectedFile}>
                    Select a Simulation Data
                </option>
                {jsonFiles.map((file, index) => (
                    <option key={index} value={'/Outputs/' + file}>
                        {'/Outputs/' + file}
                    </option>
                ))}
            </select>
            <Analytics />
        </div>
    );
};
// =======================================================================================
export default Dashboard;
// END  ==================================================================================
// =======================================================================================