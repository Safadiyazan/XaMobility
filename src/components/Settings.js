import React, { useState } from 'react';
import Accordion from 'react-bootstrap/Accordion';
import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';

function Settings() {

    const [saveSuccess, setSaveSuccess] = useState(false);
    const [lastSavedTimestamp, setLastSavedTimestamp] = useState(null);
    const savedButton = document.getElementById('savedButton');

    const [values, setValues] = useState({
        dx: 500,
        dy: 500,
        dz: 100,
        VmaxMin: 10,
        VmaxMax: 30,
        RsMin: 10,
        RsMax: 30,
        Qin: 0.1,
    });

    const handleChange = (event) => {
        const { id, value } = event.target;
        setValues((prevValues) => ({ ...prevValues, [id]: parseFloat(value) }));
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
            },
            Aircraft: {
                VmaxMin: values.VmaxMin,
                VmaxMax: values.VmaxMax,
                RsMin: values.RsMin,
                RsMax: values.RsMax
            },
            Sim: {
                Qin: values.Qin,
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
                                                    <Form.Label>dx:</Form.Label>
                                                    <Form.Control
                                                        type="number"
                                                        value={values.dx}
                                                        onChange={handleChange}
                                                        min={500}
                                                        max={30000}
                                                        step={100}
                                                    />
                                                </Form.Group>
                                            </div>

                                            <div className="col">
                                                <Form.Group controlId="dy" className="mb-3">
                                                    <Form.Label>dy:</Form.Label>
                                                    <Form.Control
                                                        type="number"
                                                        value={values.dy}
                                                        onChange={handleChange}
                                                        min={500}
                                                        max={30000}
                                                        step={100}
                                                    />
                                                </Form.Group>
                                            </div>

                                            <div className="col">
                                                <Form.Group controlId="dz" className="mb-3">
                                                    <Form.Label>dz:</Form.Label>
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
                                                    <td>Maximum speed</td>
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
                                                    <td>Safety radius</td>
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
                                            <Form.Label>Qin:</Form.Label>
                                            <Form.Control
                                                type="number"
                                                value={values.Qin}
                                                onChange={handleChange}
                                                min={0.1}        // Set the minimum value
                                                max={2}      // Set the maximum value
                                                step={0.1}     // Set the step value  
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
                                Save settings in server
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
