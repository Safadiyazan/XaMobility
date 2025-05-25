> ⚠️ This repository is under active development. We appreciate your patience as features, documentation, and examples are continuously being developed.

# XaMobility

This repository provides an open-source research tool for simulating and visualizing air mobility (AM) operations in low-altitude airspace.

More info about the research can be viewed in the attached seminar:  
[![Watch the seminar](https://img.youtube.com/vi/50ZTlQwncGQ/hqdefault.jpg)](https://youtu.be/50ZTlQwncGQ)

---

## Usage Notice

Use of this repository requires prior registration.

**Please complete the following form before using or distributing this repository:**  
📄 [XaMobility Access Form](https://forms.gle/UhkTWUsA5uwBvQDC6)

By accessing or using this repository, you agree not to redistribute the content or use it for commercial purposes without prior written permission from the author.

## Prerequisites

Before using this repository, ensure you have the following installed:

- **Cesium JS Token**  
    A Cesium JS Token is required for accessing Cesium's services. Obtain a token by signing up at [Cesium ion](https://cesium.com/ion/). Once you have the token, create a `token.js` file in the main directory with the following content:  
    ```javascript
    const token = "your_token_here";
    export default token;
    ```
    Replace `"your_token_here"` with your actual Cesium JS Token. Ensure this file is not exposed publicly by adding it to your `.gitignore` file.

- **Node.js (v14 or higher)**  
    Download and install Node.js from [nodejs.org](https://nodejs.org/).

- **npm (Node Package Manager)**  
    npm is included with Node.js. Ensure it is installed and updated:  
    ```bash
    npm install -g npm@latest
    ```

- **Python (v3.7 or higher)**  
    Ensure you have Python version 3.7 or higher installed, as it should be compatible with the MATLAB Engine API for Python.
    Download and install Python from [python.org](https://www.python.org/). Ensure Python is added to your system's PATH.

- **pip (Python Package Installer)**  
    pip is included with Python. Verify it is installed and updated:  
    ```bash
    python -m ensurepip --upgrade
    python -m pip install --upgrade pip
    ```

- **MATLAB Engine API for Python**  
    The MATLAB Engine API for Python is required for certain functionalities. Ensure it is installed and configured:  
    ```bash
    python -m pip install matlabengine
    ```
    For more details, refer to the [MATLAB Engine API for Python Documentation](https://www.mathworks.com/help/matlab/matlab_external/get-started-with-matlab-engine-for-python.html).

- **Git**  
    Install Git for version control: [git-scm.com](https://git-scm.com/).

---

## Setup Instructions

1. **Clone the Repository**  
     Clone this repository to your local machine:  
     ```bash
     git clone https://github.com/your-username/XaMobility.git
     cd XaMobility
     ```

2. **Python Requirements**  
    Install the required Python packages using the provided `requirements_pip.txt` file:  
    ```bash
    python -m pip install -r requirements_pip.txt
    ```
    Please note that it might be that only Flask is needed.

3. **Install Dependencies**  
     Install the required npm packages:  
     ```bash
     npm install
     ```

4. **Run the Application**  
     Start the application using the following command:  
     ```bash
     npm start
     ```

You're now ready to use XaMobility!

---

## Acknowledgments

This project was developed as part of a doctoral research thesis at the **Faculty of Civil and Environmental Engineering, Technion**, under the supervision of **Assoc. Prof. Jack Haddad** (Technion) and co-supervision of **Prof. Nikolas Geroliminis** (EPFL).

The author affirms that the research — including data collection, processing, analysis, and reporting — was conducted with integrity and in accordance with the ethical standards of scientific research.

The generous support of the following institutions is gratefully acknowledged:

- **Chil and Berta Weissmann Doctoral Fellowship**  
- **ISTRC**  
- **EuroTech Alliance**  
- **Technion - CEE - T-SMART**
- **EPFL - LUTS**
- **Beihang University - BUAA**
- **Cesium**

## Collaborators and Special Thanks

Thanks to Kfir Assor, BAI Shuangxia, GAO Yang, Ayelet Gal-Tzur, Nikolas Geroliminis, Assaf Granot, Ramiz Elaiyan, Nizar Jbara, Miran Khweis, Lishuai LI, Boris Mirkin, Quan Quan, Rami Sabbagh, Tal Zameret, and Ron Zehavi, and especially Rao Fu, for their collaboration, discussions, and contributions to the development of this work.

---

For questions, feedback, or support, please contact:  
**Yazan Safadi** — [safadiyazan@gmail.com](mailto:safadiyazan@gmail.com)

---

## License

This repository is open-source and distributed under the [Apache 2.0 License](LICENSE).
