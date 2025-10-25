import { useState, useEffect, useRef } from 'react';
import type { Column, Task } from '../types';
import { ApiService } from '../api';
import FieldRenderer from './FieldRenderer';
import ColumnManager from './ColumnManager';

interface NotionTableProps {
  apiService: ApiService;
}

let hasInitialized = false;

export default function NotionTable({ apiService }: NotionTableProps) {
  const [columns, setColumns] = useState<Column[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [showColumnManager, setShowColumnManager] = useState(false);
  const [isAddingTask, setIsAddingTask] = useState(false);
  const [newTaskFields, setNewTaskFields] = useState<Record<string, any>>({});
  const nameInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    if (isAddingTask) {
      nameInputRef.current?.focus();
    }
  }, [isAddingTask]);

  const loadData = async () => {
    try {
      let columnsData = await apiService.getColumns();
      if (columnsData.length === 0 && !hasInitialized) {
        hasInitialized = true; // Prevent infinite loops
        await apiService.initDefaultColumns();
        columnsData = await apiService.getColumns();
      }
      const tasksData = await apiService.getTasks();
      setColumns(columnsData);
      setTasks(tasksData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleStartAddTask = () => {
    const today = new Date().toISOString().split('T')[0];
    const statusColumn = columns.find(c => c.name === 'status');
    const notStartedOption = statusColumn?.options.find(o => o.toLowerCase().includes('not started'));

    setNewTaskFields({
      due_date: today,
      category: [],
      status: notStartedOption || (statusColumn?.options[0] || ''),
      name: ''
    });
    setIsAddingTask(true);
  };

  const handleAddTask = async () => {
    try {
      await apiService.addTask(newTaskFields);
      await loadData();
      setNewTaskFields({});
      setIsAddingTask(false);
    } catch (error) {
      console.error('Error adding task:', error);
      alert('Failed to add task');
    }
  };

  const handleUpdateTask = async (task: Task, fieldName: string, value: any) => {
    const idField = columns.find(c => c.type === 'text')?.name || columns[0]?.name;
    if (!idField || !task.fields[idField]) {
      alert('Cannot update task: no identifier field');
      return;
    }

    try {
      const updates = { [fieldName]: value };
      await apiService.updateTask(task.fields[idField], updates, idField);
      await loadData();
    } catch (error) {
      console.error('Error updating task:', error);
      alert('Failed to update task');
    }
  };

  const handleDeleteTask = async (task: Task) => {
    const idField = columns.find(c => c.type === 'text')?.name || columns[0]?.name;
    if (!idField || !task.fields[idField]) {
      alert('Cannot delete task: no identifier field');
      return;
    }

    if (!confirm(`Delete this task?`)) return;

    try {
      await apiService.deleteTask(task.fields[idField], idField);
      await loadData();
    } catch (error) {
      console.error('Error deleting task:', error);
      alert('Failed to delete task');
    }
  };

  const handleAddColumn = async (column: Omit<Column, 'order'>) => {
    await apiService.addColumn(column);
    await loadData();
  };

  const handleUpdateColumn = async (name: string, updates: { new_type?: string; new_options?: string[] }) => {
    await apiService.updateColumn(name, updates);
    await loadData();
  };

  const handleDeleteColumn = async (name: string) => {
    await apiService.deleteColumn(name);
    await loadData();
  };

  const handleNameKeyDown = async (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      const taskName = newTaskFields['name'];
      if (taskName) {
        const suggestedCategory = await apiService.suggestCategory(taskName);
        if (suggestedCategory) {
          setNewTaskFields(prev => ({
            ...prev,
            category: [...(prev.category || []), suggestedCategory]
          }));
        }
      }
    }
  };

  if (loading) {
    return <div className="d-flex justify-content-center align-items-center vh-100"><h2>Loading...</h2></div>;
  }

  return (
    <div className="container mt-5">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h1>Assignment Tracker</h1>
        <div className="d-flex gap-2">
          <button className="btn btn-secondary" onClick={() => setShowColumnManager(true)}>
            Manage Columns
          </button>
          <button className="btn btn-primary" onClick={handleStartAddTask}>
            Add Row
          </button>
        </div>
      </div>

      <table className="table table-hover align-middle">
        <thead className="table-light">
          <tr>
            {columns.map(column => (
              <th key={column.name} scope="col">{column.name}</th>
            ))}
            <th scope="col">Actions</th>
          </tr>
        </thead>
        <tbody>
          {isAddingTask && (
            <tr className="table-primary">
              {columns.map(column => (
                <td key={column.name}>
                  <FieldRenderer
                    ref={column.name === 'name' ? nameInputRef : null}
                    column={column}
                    value={newTaskFields[column.name]}
                    onChange={(value) => setNewTaskFields({ ...newTaskFields, [column.name]: value })}
                    onKeyDown={column.name === 'name' ? handleNameKeyDown : undefined}
                  />
                </td>
              ))}
              <td>
                <button className="btn btn-sm btn-success me-2" onClick={handleAddTask}>Save</button>
                <button className="btn btn-sm btn-danger" onClick={() => { setIsAddingTask(false); setNewTaskFields({}); }}>Cancel</button>
              </td>
            </tr>
          )}

          {tasks.map((task, idx) => (
            <tr key={idx}>
              {columns.map(column => (
                <td key={column.name}>
                  <FieldRenderer
                    column={column}
                    value={task.fields[column.name]}
                    onChange={(value) => handleUpdateTask(task, column.name, value)}
                  />
                </td>
              ))}
              <td>
                <button className="btn btn-sm btn-outline-danger" onClick={() => handleDeleteTask(task)} title="Delete">
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {tasks.length === 0 && !isAddingTask && (
        <div className="text-center p-5">
          <p>No rows yet. Click "Add Row" to get started!</p>
        </div>
      )}

      {showColumnManager && (
        <ColumnManager
          columns={columns}
          onAdd={handleAddColumn}
          onUpdate={handleUpdateColumn}
          onDelete={handleDeleteColumn}
          onClose={() => setShowColumnManager(false)}
        />
      )}
    </div>
  );
}
