import React, { useState } from 'react';
import Accordion from 'react-bootstrap/Accordion';
import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';
import '.././css/main.css'; // Ensure this import is here

function Settings() {

    const [saveSuccess, setSaveSuccess] = useState(false);
    const [lastSavedTimestamp, setLastSavedTimestamp] = useState(null);
    const savedButton = document.getElementById('savedButton');
    const runButton = document.getElementById('runButton');

    const [values, setValues] = useState({
        dx: 1500,
        dy: 1500,
        dz: 100,
        asStr: 'Subset',
        VmaxMin: 10,
        VmaxMax: 30,
        RsMin: 10,
        RsMax: 30,
        Qin: 6,
        SceStr: '',
    });

    const handleChange = (event) => {
        const { id, value } = event.target;
        const newValue = ((id === 'SceStr') || (id === 'asStr')) ? value.replace(/\s/g, '') : parseFloat(value);
        setValues((prevValues) => ({ ...prevValues, [id]: newValue }));
        setSaveSuccess(false);
        savedButton.classList.remove('btn-success');
        savedButton.classList.remove('btn-danger');
        savedButton.classList.add('btn-primary');
    };

    const handleChangeString = (event) => {
        const { name, value } = event.target; // Use 'name' here
        const newValue = (name === 'SceStr' || name === 'asStr') ? value.replace(/\s/g, '') : parseFloat(value);
        setValues((prevValues) => ({ ...prevValues, [name]: newValue }));
        setSaveSuccess(false);
        savedButton.classList.remove('btn-success');
        savedButton.classList.remove('btn-danger');
        savedButton.classList.add('btn-primary');
    };

    const handleSave = (values) => {
        // Create the NewSettings object
        const NewSettings = {
            Airspace: {
                dx: values.dx,
                dy: values.dy,
                dz: values.dz,
                asStr: values.asStr
            },
            Aircraft: {
                VmaxMin: values.VmaxMin,
                VmaxMax: values.VmaxMax,
                RsMin: values.RsMin,
                RsMax: values.RsMax
            },
            Sim: {
                Qin: values.Qin,
                SceStr: values.SceStr
            },
        };

        // You can now send the 'NewSettings' object back to the server
        console.log('Saving settings to server:', NewSettings);

        // Perform the actual API call to send 'NewSettings' to the server
        // Example:
        try {
            savedButton.classList.remove('btn-success');
            savedButton.classList.remove('btn-primary');
            savedButton.classList.add('btn-danger');
            fetch('/api/save_settings', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ NewSettings }),
            })
                .then(response => response.json())
                .then(data => console.log('Server response:', data))
                .catch(error => console.error('Error:', error));
            // Set the last saved timestamp
            const timestamp = new Date().toLocaleString();
            setLastSavedTimestamp(timestamp);
            // Indicate save success
            setSaveSuccess(true);
            runButton.classList.add('btn-success');

        } catch (error) {
            console.error('Error:', error);
            setSaveSuccess(false);
        } finally {
            savedButton.classList.remove('btn-danger');
            savedButton.classList.add('btn-success');
        }

    };

    return (
        <div>
            <hr />
            <Accordion defaultActiveKey="0">
                <Accordion.Item eventKey="1">
                    <Accordion.Header>
                        <center>
                            <b>
                                <h4>Settings</h4>
                            </b>
                        </center>
                    </Accordion.Header>
                    <Accordion.Body>
                        <Accordion defaultActiveKey="0">
                            <Accordion.Item eventKey="1">
                                <Accordion.Header>Airspace settings</Accordion.Header>
                                <Accordion.Body>
                                    <Form className="text-center">
                                        <div className="row">
                                            <div className="col">
                                                <Form.Group controlId="dx" className="mb-3">
                                                    <Form.Label>dx [m]:</Form.Label>
                                                    <Form.Control
                                                        type="number"
                                                        value={values.dx}
                                                        onChange={handleChange}
                                                        min={500}
                                                        max={30000}
                                                        step={500}
                                                    />
                                                </Form.Group>
                                            </div>

                                            <div className="col">
                                                <Form.Group controlId="dy" className="mb-3">
                                                    <Form.Label>dy [m]:</Form.Label>
                                                    <Form.Control
                                                        type="number"
                                                        value={values.dy}
                                                        onChange={handleChange}
                                                        min={500}
                                                        max={30000}
                                                        step={500}
                                                    />
                                                </Form.Group>
                                            </div>

                                            <div className="col">
                                                <Form.Group controlId="dz" className="mb-3">
                                                    <Form.Label>dz [m]:</Form.Label>
                                                    <Form.Control
                                                        type="number"
                                                        value={values.dz}
                                                        onChange={handleChange}
                                                        min={30}
                                                        max={300}
                                                        step={10}
                                                    />
                                                </Form.Group>
                                            </div>
                                        </div>
                                        <div className="col">
                                            <Form.Group controlId="dropdown" className="mb-3">
                                                <Form.Label>Airspace structure:</Form.Label>
                                                <Form.Select
                                                    name="asStr"
                                                    value={values.asStr}
                                                    onChange={handleChangeString}
                                                >
                                                    <option value="Subset">Subset</option>
                                                    <option value="VTOL">VTOL</option>
                                                    <option value="NYC">NYC</option>
                                                    <option value="SF">SF</option>
                                                    <option value="PAR">PAR</option>
                                                    {/* <option value="AS2">VTOL-2R</option> */}
                                                </Form.Select>
                                            </Form.Group>
                                        </div>
                                    </Form>
                                </Accordion.Body>
                            </Accordion.Item>
                            <Accordion.Item eventKey="2">
                                <Accordion.Header>Aircraft settings</Accordion.Header>
                                <Accordion.Body>
                                    <Form className="text-center">
                                        <table className="table">
                                            <thead>
                                                <tr>
                                                    <th>Value</th>
                                                    <th>Min</th>
                                                    <th>Max</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr>
                                                    <td>Maximum speed [m/s]</td>
                                                    <td>
                                                        <Form.Group controlId="VmaxMin">
                                                            <Form.Control
                                                                type="number"
                                                                value={values.VmaxMin}
                                                                onChange={handleChange}
                                                                min={10}
                                                                max={values.VmaxMax}
                                                                step={1}
                                                            />
                                                        </Form.Group>
                                                    </td>
                                                    <td>
                                                        <Form.Group controlId="VmaxMax">
                                                            <Form.Control
                                                                type="number"
                                                                value={values.VmaxMax}
                                                                onChange={handleChange}
                                                                min={values.VmaxMin}
                                                                max={30}
                                                                step={1}
                                                            />
                                                        </Form.Group>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td>Safety radius [m]</td>
                                                    <td>
                                                        <Form.Group controlId="RsMin">
                                                            <Form.Control
                                                                type="number"
                                                                value={values.RsMin}
                                                                onChange={handleChange}
                                                                min={10}
                                                                max={values.RsMax}
                                                                step={1}
                                                            />
                                                        </Form.Group>
                                                    </td>
                                                    <td>
                                                        <Form.Group controlId="RsMax">
                                                            <Form.Control
                                                                type="number"
                                                                value={values.RsMax}
                                                                onChange={handleChange}
                                                                min={values.RsMin}
                                                                max={30}
                                                                step={1}
                                                            />
                                                        </Form.Group>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </Form>
                                </Accordion.Body>
                            </Accordion.Item>
                            <Accordion.Item eventKey="3">
                                <Accordion.Header>Simulation settings</Accordion.Header>
                                <Accordion.Body>
                                    <Form>
                                        <Form.Group controlId="Qin">
                                            <Form.Label>Qin [aircraft/m]:</Form.Label>
                                            <Form.Control
                                                type="number"
                                                value={values.Qin}
                                                onChange={handleChange}
                                                min={1}        // Set the minimum value
                                                max={2}      // Set the maximum value
                                                step={1}     // Set the step value  
                                            />
                                        </Form.Group>
                                        <Form.Group controlId="SceStr">
                                            <Form.Label>Scenario name:</Form.Label>
                                            <Form.Control
                                                type="text"
                                                onChange={handleChange}
                                            />
                                        </Form.Group>
                                    </Form>
                                </Accordion.Body>
                            </Accordion.Item>
                        </Accordion>
                        <br />
                        <center>
                            {lastSavedTimestamp && (
                                <p className="text-success">Settings last saved: {lastSavedTimestamp}</p>
                            )}
                            <Button id='savedButton' variant="primary" onClick={() => handleSave(values)} disabled={saveSuccess}>
                                Save settings on the server
                            </Button>
                        </center>
                    </Accordion.Body>
                </Accordion.Item>
            </Accordion>
            <hr />
        </div>
    );
}

export default Settings;
