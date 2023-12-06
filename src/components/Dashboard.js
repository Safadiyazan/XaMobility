import React, { useState, useEffect } from 'react';

import { LoadSimulation } from '.././LoaderSimulation';

import { viewer } from '.././index';

const Dashboard = () => {

    // ============ MATLAB Code =========================
    const runMatlabCode = async () => {
        try {
            const response = await fetch('http://localhost:1110/run_matlab_code', {
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

    const [selectedFile, setSelectedFile] = useState("/LAATSimData/SimOutput_ObjAircraft.json");

    // ... Other code

    useEffect(() => {
        // Fetch initial data when the component mounts
        const initialSelectedFile = selectedFile;
        fetch(initialSelectedFile)
            .then(response => response.json())
            .then(data => {
                // Call your function with the fetched data
                LoadSimulation(viewer,data);
            })
            .catch(error => {
                console.error('Error fetching data:', error);
            });
    }, [selectedFile]);  // Dependency array ensures this effect runs when selectedFile changes



    return (
        <div className="container mt-5">
            <h1>Dashboard</h1>
            <button onClick={runMatlabCode}>Run MATLAB Code</button>
            <div id="result-container"></div>
            <h2>Menu</h2>
            <hr />
            <div className="row mt-4">
                <div className="col-md-6">
                    <form action="/upload" method="post" encType="multipart/form-data" onSubmit={handleSubmit}>
                        <div className="form-group">
                            <label htmlFor="file">Select a simulation output:</label>
                            <input type="file" className="form-control" id="file" name="file" accept=".json" onChange={handleFileChange} required />
                        </div>
                        <button type="submit" className="btn btn-primary">Send JSON file</button>
                    </form>
                </div>
                <div className="col-md-6">
                    <div className="form-group">
                        <label htmlFor="filenameDropdown">Select a simulation sample:</label>
                        <select className="form-control" id="filenameDropdown" onChange={handleDropdownChange} value={selectedFile}>
                            <option value="/LAATSimData/SimOutput_ObjAircraft.json">Default</option>
                            <option value="/LAATSimData/SimOutput_ObjAircraft.json">VTOL Control Concept</option>
                            <option value="/LAATSimData/SimOutput_ObjAircraft_Subset_LowDemand.json">Subset Low Demand</option>
                            <option value="/LAATSimData/SimOutput_ObjAircraft_Subset_LowMidDemand.json">Subset Mid Demand</option>
                        </select>
                    </div>
                </div>
            </div>
            <p className="mt-3">Selected File: {selectedFile}</p>
        </div>
    );
};

export default Dashboard;
// END  ==================================================================================
// =======================================================================================