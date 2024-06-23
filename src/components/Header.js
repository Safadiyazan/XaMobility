// src/components/Header.js
import React from 'react';
import { Navbar, Nav, Button, NavDropdown } from 'react-bootstrap';
import '.././css/main.css'; // Ensure this import is here

const Header = ({ isAuthenticated, onLoginButtonClick, username, onLogout }) => {
  return (
    <Navbar bg="dark" variant="dark" expand="lg">
      <Navbar.Brand href="/">
        <img
          alt="Logo TSMART"
          src="/ALSim_Logo.png"
          width="30"
          height="40"
          className="d-inline-block align-center"
        />{' '}
        LAAT Flow Simulation
      </Navbar.Brand>
      <Navbar.Toggle aria-controls="basic-navbar-nav" />
      <Nav className="ml-auto">
        {!isAuthenticated ? (
          <Button variant="outline-light" onClick={onLoginButtonClick} href="/login">
            Login
          </Button>
        ) : (
          <NavDropdown title={isAuthenticated ? `Welcome, ${username}` : 'Login'} id="basic-nav-dropdown">
            <NavDropdown.Item onClick={() => onLogout()}>
              Signout
            </NavDropdown.Item>
          </NavDropdown>
        )}
      </Nav>
    </Navbar>
  );
};

export default Header;