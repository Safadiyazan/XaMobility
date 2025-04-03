import React, { useState } from 'react';
import '.././css/main.css';

const ImageToolbar = () => {
  const [isChecked, setIsChecked] = useState(false);

  const handleCheckboxChange = (event) => {
    setIsChecked(event.target.checked);
  };

  return (
    <div id="image-toolbar">
      <input
        type="checkbox"
        id="showImage"
        checked={isChecked}
        onChange={handleCheckboxChange}
      />
      <label htmlFor="showImage"> Show Keyboard Setting</label>
      {isChecked && <img src="/Keyboard.png" alt="Keyboard" style={{ width: '280px' }} />}
    </div>
  );
};

export default ImageToolbar;
