import React from 'react';
import type { Column } from '../types';
import MultiSelect from './MultiSelect';
import StatusSelect from './StatusSelect';

interface FieldRendererProps {
  column: Column;
  value: any;
  onChange: (value: any) => void;
  onKeyDown?: (e: React.KeyboardEvent<HTMLInputElement>) => void;
  onBlur?: () => void;
  disabled?: boolean;
}

const FieldRenderer = React.forwardRef<HTMLInputElement, FieldRendererProps>(
  ({ column, value, onChange, onKeyDown, onBlur, disabled = false }, ref) => {
    switch (column.type) {
      case 'text':
        return (
          <input
            ref={ref}
            className="form-control no-focus-ring"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            onKeyDown={onKeyDown}
            onBlur={onBlur}
            disabled={disabled}
            placeholder={`Enter ${column.name}...`}
          />
        );

      case 'date':
        return (
          <input
            type="date"
            className="form-control no-focus-ring"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            disabled={disabled}
          />
        );

      case 'select':
        if (column.options.length === 0) {
          return <span className="text-muted">No options defined</span>;
        }
        return (
          <StatusSelect
            value={value || column.options[0]}
            options={column.options}
            onChange={onChange}
          />
        );

      case 'multiselect':
        if (column.options.length === 0) {
          return <span className="text-muted">No options defined</span>;
        }
        return (
          <MultiSelect
            options={column.options}
            selected={Array.isArray(value) ? value : []}
            onChange={onChange}
            placeholder={`Select ${column.name}...`}
          />
        );

      default:
        return <span className="text-danger">Unknown field type: {column.type}</span>;
    }
  }
);

export default FieldRenderer;

interface FieldDisplayProps {
  column: Column;
  value: any;
}

export function FieldDisplay({ column, value }: FieldDisplayProps) {
  if (value === null || value === undefined || value === '') {
    return <span className="text-muted">-</span>;
  }

  switch (column.type) {
    case 'text':
    case 'date':
      return <span>{value}</span>;

    case 'select':
      return <span className="badge bg-primary">{value}</span>;

    case 'multiselect':
      if (!Array.isArray(value) || value.length === 0) {
        return <span className="text-muted">-</span>;
      }
      return (
        <div className="d-flex gap-1 flex-wrap">
          {value.map((item, idx) => (
            <span key={idx} className="badge bg-secondary">{item}</span>
          ))}
        </div>
      );

    default:
      return <span>{JSON.stringify(value)}</span>;
  }
}
