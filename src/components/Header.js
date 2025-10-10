// src/components/Header.js
import React from 'react';
import { Navbar } from 'react-bootstrap';
import '.././css/main.css';

const Header = () => {
  return (
    <Navbar bg="dark" variant="dark" expand="lg">
      <Navbar.Brand href="/">
        <img
          alt="Logo XaMobility"
          src="/logo.png"
          width="30"
          height="40"
          className="d-inline-block align-center"
        />{' '}
        XaMobility
      </Navbar.Brand>
    </Navbar>
  );
};

export default Header;