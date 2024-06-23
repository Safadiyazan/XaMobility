import React, { useState } from 'react';
import '.././css/main.css'; // Ensure this import is here

const ImageToolbar = () => {
  const [isChecked, setIsChecked] = useState(false); // Initially unchecked

  const handleCheckboxChange = (event) => {
    setIsChecked(event.target.checked);
  };

  return (
    <div id="image-toolbar">
      <input
        type="checkbox"
        id="showImage"
        checked={isChecked} // Set checkbox state
        onChange={handleCheckboxChange}
      />
      <label htmlFor="showImage"> Show Keyboard Setting</label>
      {isChecked && <img src="/Keyboard.png" alt="Keyboard" style={{ width: '280px' }} />}
    </div>
  );
};

export default ImageToolbar;
