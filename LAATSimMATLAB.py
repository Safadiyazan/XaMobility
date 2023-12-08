# static/LAATSimMATLAB.py
from flask import Flask, jsonify
from flask_cors import CORS
import matlab.engine
import datetime
import atexit

app = Flask(__name__, static_url_path='/')
CORS(app, resources={r"/run_matlab_code": {"origins": "http://localhost:1110"}})
eng = matlab.engine.start_matlab("-nojvm")
eng.addpath('./pyLAATSimV0100', nargout=0)

def runMatlabCode():
    try:
        # Your MATLAB code
        print(datetime.datetime.now())
        NewJSONDir = eng.RunLAATSim(1, '', nargout=1)
        print(NewJSONDir)

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
