import React, { useState } from 'react';

const CityDropdown = ({ handleDropdownCityChange, selectedCity }) => {
  return (
    <div id="dropdown-city-container">
      <span className="dropdown-city-label">Select City:</span>
      <select id="dropdown-city" onChange={handleDropdownCityChange} value={selectedCity}>
        <option value="NYC">NYC</option>
        <option value="SF">SF</option>
        <option value="ZH">ZH</option>
        <option value="NZ">NZ</option>
        <option value="HF">HF</option>
        <option value="DXB">DXB</option>
        <option value="KTH">KTH</option>
      </select>
    </div>
  );
};

export default CityDropdown;
