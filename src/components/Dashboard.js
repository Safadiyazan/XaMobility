import React, { useState, useEffect, useRef } from 'react';
import Accordion from 'react-bootstrap/Accordion';
import axios from 'axios';

import Analytics from './Analytics';
import Settings from './Settings';
import { LoadSimulation } from '.././LoaderSimulation';
import { viewer } from '.././index';
import CityDropdown from './CityDropdown';
import ImageToolbar from './ImageToolbar';
import ViewerToolBar from './ViewerToolBar';
import NetworkSetup from './NetworkSetup.js';
import '.././css/main.css';

const Dashboard = () => {
    // =======================================================================================
    // MATLAB Call ===========================================================================
    // ============ MATLAB Code =========================
    const [setRunning, setRunningSuccess] = useState(false);
    const [setRestart, setRestartSuccess] = useState(true);

    const runMatlabCode = async () => {
        const loadingContainer = document.getElementById('loading');
        const resultContainer = document.getElementById('result-container');
        const runButton = document.getElementById('runButton');

        try {
            setRunningSuccess(true);
            // setRestartSuccess(true);
            loadingContainer.style.display = 'block';
            runButton.classList.remove('btn-primary');
            runButton.classList.remove('btn-success');
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
            resultContainer.innerHTML = 'Scenario completed. ' + 'Last run: ' + data.result;
            runButton.classList.remove('btn-danger');
            runButton.classList.add('btn-secondary');
            setRunningSuccess(false);
            await fetchJsonFiles();
        } catch (error) {
            console.error('Error:', error);
            resultContainer.innerHTML = 'Error: ' + error.message;
        } finally {
            loadingContainer.style.display = 'none';
            runButton.classList.remove('btn-danger');
        }
    };

    const restart_MatlabCode = async () => {
        const restartButton = document.getElementById('restartButton');
        try {
            // setRestartSuccess(false);
            restartButton.classList.remove('btn-danger');
            restartButton.classList.remove('btn-warning');
            restartButton.classList.add('btn-secondary');
            const response = await fetch('/api/reset_matlab_engine', {
                method: 'POST',
            });
            console.log('Engine Restarted');
            restartButton.classList.remove('btn-secondary');
            restartButton.classList.add('btn-danger');
            runButton.classList.add('btn-primary');
            setRunningSuccess(false);
            // setRestartSuccess(true);
            // alert('Engine restarted successfully!');
        } catch (error) {
            console.error('Error restarting engine:', error);
            // alert('Error restarting engine: ' + error.message);
        }
    }

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

    // GUI Handles ===========================================================================
    // Handle file dropdown change
    const handleDropdownChange = (event) => {
        const selectedOption = event.target.value;
        setSelectedFile(selectedOption);
    };

    const handleDropdownCityChange = (event) => {
        const selectedCityOption = event.target.value;
        console.log(`Selected City option 1: ${selectedCityOption}`);
        setSelectedCity(selectedCityOption);
    };
    const [navigationOn, setNavigationOn] = useState(false);

    const handleCheckboxChange = () => {
        const isChecked = !navigationOn;
        setNavigationOn(isChecked);
        NavigationOn = 1;
        console.log('Checkbox Checked:', isChecked);
    };
    // =======================================================================================
    // Run and Load Simulation Handles =======================================================
    const [selectedFile, setSelectedFile] = useState("/Samples/Results_Qin2Subset_2by2_10apm.json");
    const [analyticsData, setAnalyticsData] = useState(null);

    useEffect(() => {
        const initialSelectedFile = selectedFile;
        const initialSelectedCity = selectedCity;
        fetch(initialSelectedFile)
            .then(response => response.json())
            .then(data => {
                console.log(`Selected Data name: ${initialSelectedFile}`);
                console.log(`Selected Data city name: ${initialSelectedCity}`);
                LoadSimulation(viewer, data, initialSelectedCity);
                setAnalyticsData(data);
            })
            .catch(error => {
                console.error('Error fetching data:', error);
            });
    }, [selectedFile]);

    const [selectedCity, setSelectedCity] = useState("NYC");
    useEffect(() => {
        const initialSelectedCity = selectedCity;
        const initialSelectedFile = selectedFile;
        fetch(initialSelectedFile)
            .then(response => response.json())
            .then(data => {
                LoadSimulation(viewer, data, initialSelectedCity);
                setAnalyticsData(data);
            })
            .catch(error => {
                console.error('Error fetching city:', error);
            });
    }, [selectedCity]);

    // =======================================================================================
    // Groups ================================================================================
    const [isContentVisible, setIsContentVisible] = useState(false);

    const handleToggleContent = () => {
        setIsContentVisible(!isContentVisible);
    };
    const resultContainerStyle = {
        wordWrap: 'break-word',
        overflowWrap: 'break-word',
        whiteSpace: 'pre-wrap',
    };
    // =======================================================================================
    // GUI ===================================================================================
    return (
        <div className="container mt-5">
            <h3>Dashboard</h3>
            <div className="form-group text-center">
                <select className="form-select" id="filenameDropdown" onChange={handleDropdownChange} value={selectedFile}>
                    <option value={selectedFile}>
                        Choose a sample for display
                    </option>
                    <option value="/Samples/Results_Qin2Subset_2by2_10apm.json">Subset</option>
                </select>
            </div>
            <br />
            {/* /* <Settings updateButtonClass={updateButtonClass} /> */}
            <Settings />
            <hr />
            <Accordion defaultActiveKey="0">
                <Accordion.Item eventKey="1">
                    <Accordion.Header>
                        <center><b><h4>Run simulation scenario</h4></b></center>
                    </Accordion.Header>
                    <Accordion.Body>
                        <div className="container">
                            <div className="row align-items-center justify-content-center">
                                <div className="col-md-3">
                                    <button
                                        id="runButton"
                                        className="btn btn-primary btn-block mb-3"
                                        onClick={runMatlabCode}
                                        disabled={setRunning}
                                    >
                                        Run a new scenario on the engine
                                    </button>
                                </div>
                                <div className="col-md-3 text-center">
                                    <div id="loading" style={{ display: 'none' }}>
                                        <p>Running...</p>
                                        <div className="spinner-border" role="status">
                                            <span className="sr-only"></span>
                                        </div>
                                    </div>
                                </div>
                                <div className="col-md-3">
                                    <div id="result-container" className="mt-3" style={resultContainerStyle}></div>
                                </div>
                                <div className="col-md-3">
                                    <button
                                        id="restartButton"
                                        className="btn btn-warning btn-block mb-3"
                                        onClick={restart_MatlabCode}
                                        // disabled={setRestart}
                                    >
                                        Reset engine
                                    </button>
                                </div>
                            </div>
                        </div>
                        <label htmlFor="jsonDropdown"><b>Choose a new scenario for display:</b></label>
                        <select className="form-select" id="jsonDropdown" onChange={handleDropdownChange} value={selectedFile}>
                            <option value={selectedFile}>
                                Choose a new scenario for display
                            </option>
                            {jsonFiles.map((file, index) => (
                                <option key={index} value={'/Outputs/' + file}>
                                    {file}
                                </option>
                            ))}
                        </select>
                        <div style={resultContainerStyle}>
                            <b><center><p className="mt-3">Viewer selected file: {selectedFile}</p></center></b>
                        </div>
                    </Accordion.Body>
                </Accordion.Item>
            </Accordion>
            <hr />
            <Analytics data={analyticsData} />
            <CityDropdown handleDropdownCityChange={handleDropdownCityChange} selectedCity={selectedCity} />
            <ViewerToolBar />
            <ImageToolbar />
            {/* <NetworkSetup /> */}
        </div>
    );
};
// =======================================================================================
export default Dashboard;
// END  ==================================================================================
// =======================================================================================