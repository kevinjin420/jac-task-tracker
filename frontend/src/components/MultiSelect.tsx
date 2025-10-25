import { useState, useRef, useEffect } from 'react';
import type { CategoryOption } from '../types';

interface MultiSelectProps {
  options: (string | CategoryOption)[];
  selected: string[];
  onChange: (selected: string[]) => void;
  placeholder?: string;
  disabled?: boolean;
}

export default function MultiSelect({ options, selected, onChange, placeholder = 'Select...', disabled = false }: MultiSelectProps) {
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

  const toggleOption = (optionValue: string) => {
    if (selected.includes(optionValue)) {
      onChange(selected.filter(s => s !== optionValue));
    } else {
      onChange([...selected, optionValue]);
    }
  };

  return (
    <div className="dropdown" ref={containerRef}>
      <button
        className="btn btn-outline-secondary dropdown-toggle w-100 d-flex justify-content-between align-items-center"
        type="button"
        onClick={() => !disabled && setIsOpen(!isOpen)}
        disabled={disabled}
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
            options.map(option => {
              const optionName = typeof option === 'string' ? option : option.name;
              return (
                <a
                  key={optionName}
                  href="#"
                  className={`dropdown-item d-flex justify-content-between align-items-center ${selected.includes(optionName) ? 'active' : ''}`}
                  onClick={(e) => {
                    e.preventDefault();
                    toggleOption(optionName);
                  }}
                >
                  {optionName}
                  {selected.includes(optionName) && <span>✓</span>}
                </a>
              );
            })
          )}
        </div>
      )}
    </div>
  );
}
