import { useState, useRef, useEffect } from 'react';

interface MultiSelectProps {
  options: string[];
  selected: string[];
  onChange: (selected: string[]) => void;
  placeholder?: string;
}

export default function MultiSelect({ options, selected, onChange, placeholder = 'Select...' }: MultiSelectProps) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const toggleOption = (option: string) => {
    if (selected.includes(option)) {
      onChange(selected.filter(s => s !== option));
    } else {
      onChange([...selected, option]);
    }
  };

  return (
    <div className="dropdown" ref={containerRef}>
      <button
        className="btn btn-outline-secondary dropdown-toggle w-100 d-flex justify-content-between align-items-center"
        type="button"
        onClick={() => setIsOpen(!isOpen)}
      >
        <div className="d-flex flex-wrap gap-1">
          {selected.length === 0 ? (
            <span className="text-muted">{placeholder}</span>
          ) : (
            selected.map(item => (
              <span key={item} className="badge bg-primary">
                {item}
              </span>
            ))
          )}
        </div>
      </button>

      {isOpen && (
        <div className={`dropdown-menu w-100 show`}>
          {options.length === 0 ? (
            <span className="dropdown-item text-muted">No options available</span>
          ) : (
            options.map(option => (
              <a
                key={option}
                href="#"
                className={`dropdown-item d-flex justify-content-between align-items-center ${selected.includes(option) ? 'active' : ''}`}
                onClick={(e) => {
                  e.preventDefault();
                  toggleOption(option);
                }}
              >
                {option}
                {selected.includes(option) && <span>✓</span>}
              </a>
            ))
          )}
        </div>
      )}
    </div>
  );
}
