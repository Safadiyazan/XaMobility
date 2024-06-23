# static/LAATSimMATLAB.py
from flask import Flask, jsonify
from flask_cors import CORS
import matlab.engine
import datetime
import atexit
import json  # Import the json module
import os

app = Flask(__name__, static_url_path='/')
CORS(app, resources={r"/run_matlab_code": {"origins": "http://localhost:1110"}})
eng = matlab.engine.start_matlab("-nojvm")
eng.addpath('./pyLAATSimV0200', nargout=0)

def runMatlabCode():
    try:
        # Your MATLAB code
        print(datetime.datetime.now())
        # # Load the JSON file
        # json_file_path = os.path.join(os.getcwd(), 'public', 'NewSettings.json')
        # print(json_file_path)
        # with open(json_file_path, 'r') as json_file:
        #     NewSettings = json.load(json_file)
        
        
        
        # Check if the JSON file exists
        json_file_path = os.path.join(os.getcwd(), 'public', 'NewSettings.json')
        if os.path.exists(json_file_path):
            # Load the JSON file
            with open(json_file_path, 'r') as json_file:
                NewSettings = json.load(json_file)
            qin_value = NewSettings['Sim']['Qin']
            SceStr_value = NewSettings['Sim']['SceStr']
            NewJSONDir = eng.RunLAATSimUI(qin_value,NewSettings, SceStr_value, nargout=1)
            return jsonify({'NewJSONDir': NewJSONDir})
        else:
            NewJSONDir = eng.RunLAATSim(0.1,'', '', nargout=1)
            return jsonify({'NewJSONDir': NewJSONDir})



        return jsonify({'NewJSONDir': NewJSONDir})
    except Exception as e:
        return jsonify({'error': str(e)}), 500  # Return a 500 Internal Server Error status code

def cleanup():
    print("Shutting down MATLAB engine...")
    eng.quit()

@app.route('/run_matlab_code', methods=['GET'])
def run_matlab_code():
    return runMatlabCode()

@atexit.register
def cleanup_on_exit():
    cleanup()

if __name__ == '__main__':
    app.run(debug=True)
