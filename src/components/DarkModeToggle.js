import React, { useState, useEffect, useRef } from 'react';
import './DarkModeToggle.css';

const DarkModeToggle = () => {
  const [isDarkMode, setIsDarkMode] = useState(() => {
    const savedMode = localStorage.getItem('darkMode');
    return savedMode === 'true';
  });

  const [position, setPosition] = useState(() => {
    const savedPosition = localStorage.getItem('darkModeTogglePosition');
    return savedPosition ? JSON.parse(savedPosition) : { bottom: 20, right: 20 };
  });

  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const toggleRef = useRef(null);

  useEffect(() => {
    localStorage.setItem('darkMode', isDarkMode);
    if (isDarkMode) {
      document.body.classList.add('dark-mode');
    } else {
      document.body.classList.remove('dark-mode');
    }
  }, [isDarkMode]);

  useEffect(() => {
    localStorage.setItem('darkModeTogglePosition', JSON.stringify(position));
  }, [position]);

  const toggleDarkMode = () => {
    if (!isDragging) {
      setIsDarkMode(!isDarkMode);
    }
  };

  const handleMouseDown = (e) => {
    setIsDragging(false);
    setDragStart({
      x: e.clientX - toggleRef.current.offsetLeft,
      y: e.clientY - toggleRef.current.offsetTop
    });
  };

  const handleMouseMove = (e) => {
    if (e.buttons === 1) { // Left mouse button is pressed
      setIsDragging(true);
      const newX = e.clientX - dragStart.x;
      const newY = e.clientY - dragStart.y;
      
      const maxX = window.innerWidth - 60;
      const maxY = window.innerHeight - 60;
      
      const clampedX = Math.max(10, Math.min(newX, maxX));
      const clampedY = Math.max(10, Math.min(newY, maxY));
      
      toggleRef.current.style.left = `${clampedX}px`;
      toggleRef.current.style.top = `${clampedY}px`;
      toggleRef.current.style.bottom = 'auto';
      toggleRef.current.style.right = 'auto';
    }
  };

  const handleMouseUp = () => {
    if (isDragging) {
      const rect = toggleRef.current.getBoundingClientRect();
      const windowWidth = window.innerWidth;
      const windowHeight = window.innerHeight;
      
      // Snap to nearest corner
      const isLeft = rect.left < windowWidth / 2;
      const isTop = rect.top < windowHeight / 2;
      
      const newPosition = {
        ...(isLeft ? { left: 20 } : { right: 20 }),
        ...(isTop ? { top: 20 } : { bottom: 20 })
      };
      
      setPosition(newPosition);
      
      // Reset inline styles
      toggleRef.current.style.left = '';
      toggleRef.current.style.top = '';
      toggleRef.current.style.bottom = '';
      toggleRef.current.style.right = '';
      
      setTimeout(() => setIsDragging(false), 100);
    }
  };

  const handleTouchStart = (e) => {
    const touch = e.touches[0];
    setIsDragging(false);
    setDragStart({
      x: touch.clientX - toggleRef.current.offsetLeft,
      y: touch.clientY - toggleRef.current.offsetTop
    });
  };

  const handleTouchMove = (e) => {
    setIsDragging(true);
    const touch = e.touches[0];
    const newX = touch.clientX - dragStart.x;
    const newY = touch.clientY - dragStart.y;
    
    const maxX = window.innerWidth - 60;
    const maxY = window.innerHeight - 60;
    
    const clampedX = Math.max(10, Math.min(newX, maxX));
    const clampedY = Math.max(10, Math.min(newY, maxY));
    
    toggleRef.current.style.left = `${clampedX}px`;
    toggleRef.current.style.top = `${clampedY}px`;
    toggleRef.current.style.bottom = 'auto';
    toggleRef.current.style.right = 'auto';
  };

  const handleTouchEnd = handleMouseUp;

  const getPositionStyles = () => {
    const styles = { position: 'fixed' };
    if (position.left !== undefined) styles.left = `${position.left}px`;
    if (position.right !== undefined) styles.right = `${position.right}px`;
    if (position.top !== undefined) styles.top = `${position.top}px`;
    if (position.bottom !== undefined) styles.bottom = `${position.bottom}px`;
    return styles;
  };

  return (
    <button
      ref={toggleRef}
      className={`dark-mode-toggle ${isDragging ? 'dragging' : ''}`}
      onClick={toggleDarkMode}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
      style={getPositionStyles()}
      aria-label="Toggle dark mode"
      title="Drag to move, click to toggle dark mode"
    >
      {isDarkMode ? (
        <svg viewBox="0 0 24 24" fill="currentColor" className="theme-icon">
          <path d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
        </svg>
      ) : (
        <svg viewBox="0 0 24 24" fill="currentColor" className="theme-icon">
          <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"/>
        </svg>
      )}
      <div className="drag-hint">
        <svg viewBox="0 0 24 24" fill="currentColor" className="drag-icon">
          <path d="M9 3h6v6H9V3zm0 12h6v6H9v-6z"/>
        </svg>
      </div>
    </button>
  );
};

export default DarkModeToggle;
