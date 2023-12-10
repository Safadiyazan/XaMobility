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
        const loadingContainer = document.getElementById('loading');
        const resultContainer = document.getElementById('result-container');
        const runButton = document.getElementById('runButton'); // Add an id to the button
        const addButton = document.getElementById('addButton'); // Add an id to the button

        try {
            loadingContainer.style.display = 'block'; // Show loading indicator
            runButton.classList.add('btn-danger');
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
            resultContainer.innerHTML = 'Last run: ' + data.result;

            // Add the btn-success class to turn the button green
            addButton.classList.add('btn-success');
            
        } catch (error) {
            console.error('Error:', error);
            // Update the DOM with the error
            resultContainer.innerHTML = 'Error: ' + error.message;
        } finally {
            // Hide the loading indicator after completion
            loadingContainer.style.display = 'none';
            runButton.classList.remove('btn-danger');
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
        const addButton = document.getElementById('addButton'); // Add an id to the button
        addButton.classList.remove('btn-success');
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
            <b><center><p className="mt-3">Viewer selected file: {selectedFile}</p></center></b>
            <div className="form-group text-center">
                <select className="form-select" id="filenameDropdown" onChange={handleDropdownChange} value={selectedFile}>
                    <option value={selectedFile}>
                        Select a simulation sample to view
                    </option>
                    <option value="/Samples/SimOutput_ObjAircraft_Default.json">Default</option>
                    <option value="/Samples/SimOutput_ObjAircraft_VTOL.json">VTOL</option>
                    <option value="/Samples/SimOutput_ObjAircraft_Subset.json">Subset</option>
                    <option value="/Samples/SimOutput_ObjAircraft_Control.json">VTOL Control</option>
                    <option value="/Samples/SimOutput_ObjAircraft_Congestion_Control.json">VTOL Control - OSC</option>
                </select>
            </div>
            <br />
            <hr />
            <div className="container">
                <div className="row">
                    <div className="col-md-4">
                        <button
                            id="runButton"
                            className="btn btn-success btn-block mb-3"
                            onClick={runMatlabCode}
                        >
                            Run new simulation on server
                        </button>
                    </div>
                    <div className="col-md-4">
                        <div id="loading" style={{ display: 'none' }}>
                            <center>
                            <p>Loading...</p>
                            <div className="spinner-border" role="status">
                                <span className="sr-only"></span>
                            </div>
                            </center>
                        </div>
                    </div>
                    <div className="col-md-4">
                        <button
                            id="addButton"
                            className="btn btn-block mb-3 btn-secondary"
                            onClick={handleAddFile}
                        >
                            Refresh simulation data for viewer
                        </button>
                    </div>
                </div>
            </div>
            <div id="result-container" className="mt-3"></div>
            <br />
            <select className="form-select" id="jsonDropdown" onChange={handleDropdownChange} value={selectedFile}>
                <option value={selectedFile}>
                    Select a simulation data to view
                </option>
                {jsonFiles.map((file, index) => (
                    <option key={index} value={'/Outputs/' + file}>
                        {'/Outputs/' + file}
                    </option>
                ))}
            </select>
            <Settings />
            <Analytics />
        </div>
    );
};
// =======================================================================================
export default Dashboard;
// END  ==================================================================================
// =======================================================================================