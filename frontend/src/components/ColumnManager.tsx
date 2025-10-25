import { useState } from 'react';
import type { Column, ColumnType } from '../types';

const COLUMN_TYPES: { value: ColumnType; label: string; description: string }[] = [
  { value: 'text', label: 'Text', description: 'Single line text input' },
  { value: 'select', label: 'Select', description: 'Single choice from options' },
  { value: 'multiselect', label: 'Multi-select', description: 'Multiple choices from options' },
  { value: 'date', label: 'Date', description: 'Date picker' },
];

interface ColumnManagerProps {
  columns: Column[];
  onAdd: (column: Omit<Column, 'order'>) => Promise<void>;
  onUpdate: (name: string, updates: { new_type?: string; new_options?: string[] }) => Promise<void>;
  onDelete: (name: string) => Promise<void>;
  onClose: () => void;
}

export default function ColumnManager({ columns, onAdd, onUpdate, onDelete, onClose }: ColumnManagerProps) {
  const [newColumn, setNewColumn] = useState({
    name: '',
    type: 'text' as ColumnType,
    options: [] as string[],
  });
  const [optionsInput, setOptionsInput] = useState('');
  const [editingColumn, setEditingColumn] = useState<string | null>(null);
  const [editData, setEditData] = useState({ type: 'text' as ColumnType, options: [] as string[] });
  const [editOptionsInput, setEditOptionsInput] = useState('');
  const [loading, setLoading] = useState(false);

  const handleAdd = async () => {
    if (!newColumn.name.trim()) {
      alert('Column name is required');
      return;
    }

    setLoading(true);
    try {
      await onAdd(newColumn);
      setNewColumn({ name: '', type: 'text', options: [] });
      setOptionsInput('');
    } catch (error) {
      console.error('Error adding column:', error);
      alert('Failed to add column');
    } finally {
      setLoading(false);
    }
  };

  const handleStartEdit = (column: Column) => {
    setEditingColumn(column.name);
    setEditData({ type: column.type, options: column.options });
    setEditOptionsInput(column.options.join(', '));
  };

  const handleSaveEdit = async () => {
    if (!editingColumn) return;

    setLoading(true);
    try {
      await onUpdate(editingColumn, {
        new_type: editData.type,
        new_options: editData.options
      });
      setEditingColumn(null);
    } catch (error) {
      console.error('Error updating column:', error);
      alert('Failed to update column');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (name: string) => {
    if (!confirm(`Delete column "${name}"? This will remove the column from all tasks.`)) return;

    setLoading(true);
    try {
      await onDelete(name);
    } catch (error) {
      console.error('Error deleting column:', error);
      alert('Failed to delete column');
    } finally {
      setLoading(false);
    }
  };

  const parseOptions = (input: string): string[] => {
    return input.split(',').map(s => s.trim()).filter(s => s.length > 0);
  };

  const needsOptions = (type: ColumnType) => type === 'select' || type === 'multiselect';

  return (
    <div className="modal fade show d-block" tabIndex={-1} onClick={onClose}>
      <div className="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable" onClick={(e) => e.stopPropagation()}>
        <div className="modal-content">
          <div className="modal-header">
            <h2 className="modal-title fs-5">Manage Table Columns</h2>
            <button type="button" className="btn-close" onClick={onClose}></button>
          </div>
          <div className="modal-body">
            <div className="mb-4 pb-4 border-bottom">
              <h3>Add New Column</h3>
              <div className="mb-3">
                <label className="form-label">Column Name *</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g., Assignment, Status, Priority"
                  value={newColumn.name}
                  onChange={(e) => setNewColumn({ ...newColumn, name: e.target.value })}
                  disabled={loading}
                />
              </div>
              <div className="mb-3">
                <label className="form-label">Column Type *</label>
                <select
                  className="form-select"
                  value={newColumn.type}
                  onChange={(e) => {
                    const type = e.target.value as ColumnType;
                    setNewColumn({ ...newColumn, type, options: needsOptions(type) ? newColumn.options : [] });
                  }}
                  disabled={loading}
                >
                  {COLUMN_TYPES.map(ct => (
                    <option key={ct.value} value={ct.value}>
                      {ct.label} - {ct.description}
                    </option>
                  ))}
                </select>
              </div>

              {needsOptions(newColumn.type) && (
                <div className="mb-3">
                  <label className="form-label">Options (comma-separated) *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g., todo, in progress, done"
                    value={optionsInput}
                    onChange={(e) => {
                      setOptionsInput(e.target.value);
                      setNewColumn({ ...newColumn, options: parseOptions(e.target.value) });
                    }}
                    disabled={loading}
                  />
                </div>
              )}

              <button
                className="btn btn-primary w-100"
                onClick={handleAdd}
                disabled={loading || !newColumn.name.trim() || (needsOptions(newColumn.type) && newColumn.options.length === 0)}
              >
                Add Column
              </button>
            </div>

            <div>
              <h3>Existing Columns ({columns.length})</h3>
              {columns.length === 0 ? (
                <div className="text-center p-4 text-muted">No columns yet. Add your first column above!</div>
              ) : (
                <ul className="list-group">
                  {columns.map((column) => (
                    <li key={column.name} className="list-group-item">
                      {editingColumn === column.name ? (
                        <div>
                          <h4 className="mb-3">{column.name}</h4>
                          <div className="mb-3">
                            <label className="form-label">Type</label>
                            <select
                              className="form-select"
                              value={editData.type}
                              onChange={(e) => {
                                const type = e.target.value as ColumnType;
                                setEditData({ ...editData, type, options: needsOptions(type) ? editData.options : [] });
                              }}
                              disabled={loading}
                            >
                              {COLUMN_TYPES.map(ct => (
                                <option key={ct.value} value={ct.value}>{ct.label}</option>
                              ))}
                            </select>
                          </div>

                          {needsOptions(editData.type) && (
                            <div className="mb-3">
                              <label className="form-label">Options</label>
                              <input
                                type="text"
                                className="form-control"
                                value={editOptionsInput}
                                onChange={(e) => {
                                  setEditOptionsInput(e.target.value);
                                  setEditData({ ...editData, options: parseOptions(e.target.value) });
                                }}
                                disabled={loading}
                              />
                            </div>
                          )}
                          <div>
                            <button className="btn btn-primary me-2" onClick={handleSaveEdit} disabled={loading}>
                              Save
                            </button>
                            <button className="btn btn-secondary" onClick={() => setEditingColumn(null)} disabled={loading}>
                              Cancel
                            </button>
                          </div>
                        </div>
                      ) : (
                        <div className="d-flex justify-content-between align-items-start">
                          <div>
                            <div className="fw-bold">{column.name}</div>
                            <div>
                              <span className="badge bg-secondary me-2">{COLUMN_TYPES.find(t => t.value === column.type)?.label}</span>
                            </div>
                            {column.options.length > 0 && (
                              <div className="text-muted small mt-1">Options: {column.options.join(', ')}</div>
                            )}
                          </div>
                          <div className="d-flex gap-2">
                            <button className="btn btn-sm btn-outline-primary" onClick={() => handleStartEdit(column)} disabled={loading}>
                              Edit
                            </button>
                            <button className="btn btn-sm btn-outline-danger" onClick={() => handleDelete(column.name)} disabled={loading}>
                              Delete
                            </button>
                          </div>
                        </div>
                      )}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
