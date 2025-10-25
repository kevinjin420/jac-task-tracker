import { useState, useRef, useEffect } from 'react';

interface StatusSelectProps {
  value: string;
  options: readonly string[];
  onChange: (value: string) => void;
}

const STATUS_COLOR_MAP: Record<string, string> = {
  'todo': 'danger',
  'in progress': 'primary',
  'done': 'success',
  'not started': 'secondary',
  'submitted': 'info'
};

export default function StatusSelect({ value, options, onChange }: StatusSelectProps) {
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

  const handleSelect = (option: string) => {
    onChange(option);
    setIsOpen(false);
  };

  const getStatusColor = (status: string) => {
    return STATUS_COLOR_MAP[status.toLowerCase()] || 'secondary';
  };

  const color = getStatusColor(value);

  return (
    <div className="dropdown" ref={containerRef}>
      <button
        className={`btn btn-sm dropdown-toggle w-100 text-start bg-${color}-subtle text-${color}-emphasis`}
        type="button"
        onClick={() => setIsOpen(!isOpen)}
      >
        {value}
      </button>

      {isOpen && (
        <div className="dropdown-menu w-100 show">
          {options.map(option => (
            <a
              key={option}
              href="#"
              className={`dropdown-item ${value === option ? 'active' : ''}`}
              onClick={(e) => {
                e.preventDefault();
                handleSelect(option);
              }}
            >
              {option}
            </a>
          ))}
        </div>
      )}
    </div>
  );
}
