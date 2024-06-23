// src/components/Footer.js
import React from 'react';
import '.././css/main.css'; // Ensure this import is here

const Footer = () => {
  return (
    <footer className="bg-dark text-white p-3 mt-auto">
      <div className="container-fluid d-flex justify-content-center align-items-center">
        <p className="mb-0"> Copyright &copy; 2024 T-SMART, All rights reserved.  <br />  Contact: <a href="mailto:laatflowsim@gmail.com" className="text-white">laatflowsim@gmail.com</a></p>
      </div>
    </footer>
  );
};

export default Footer;
