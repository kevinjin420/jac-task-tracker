import { useState, useEffect, useRef } from 'react';
import type { Column, Task, CategoryOption } from '../types';
import { ApiService } from '../api';
import FieldRenderer from './FieldRenderer';

interface NotionTableProps {
  apiService: ApiService;
}

export default function NotionTable({ apiService }: NotionTableProps) {
  const [columns, setColumns] = useState<Column[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAddingTask, setIsAddingTask] = useState(false);
  const [newTaskFields, setNewTaskFields] = useState<Record<string, any>>({});
  
  const [showCategoryMenu, setShowCategoryMenu] = useState<{x: number, y: number} | null>(null);
  const [editingCategory, setEditingCategory] = useState<CategoryOption | null>(null);
  const [editContext, setEditContext] = useState('');
  const [newCategoryName, setNewCategoryName] = useState('');
  const [newCategoryContext, setNewCategoryContext] = useState('');
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number; task: Task } | null>(null);

  const nameInputRef = useRef<HTMLInputElement>(null);
  const categoryMenuRef = useRef<HTMLDivElement>(null);
  const contextMenuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadData();

    const handleClickOutside = (event: MouseEvent) => {
      if (categoryMenuRef.current && !categoryMenuRef.current.contains(event.target as Node)) {
        setShowCategoryMenu(null);
      }
      if (contextMenuRef.current && !contextMenuRef.current.contains(event.target as Node)) {
        setContextMenu(null);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  useEffect(() => {
    if (isAddingTask) {
      nameInputRef.current?.focus();
    }
  }, [isAddingTask]);

  useEffect(() => {
    if (editingCategory) {
      setEditContext(editingCategory.context);
    }
  }, [editingCategory]);

  const loadData = async () => {
    try {
      const columnsData = await apiService.getColumns();
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
    setNewTaskFields({ name: '' });
    setIsAddingTask(true);
  };

  const handleNameKeyDown = async (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      const taskName = newTaskFields.name;
      if (!taskName || !taskName.trim()) {
        setIsAddingTask(false);
        setNewTaskFields({});
        return;
      }

      try {
        await apiService.addTask(taskName);
        await loadData();
        setNewTaskFields({});
        setIsAddingTask(false);
      } catch (error) {
        console.error('Error adding task:', error);
        alert('Failed to add task with AI category.');
      }
    }
  };

  const handleUpdateTask = async (task: Task, fieldName: string, value: any) => {
    const idField = columns.find(c => c.type === 'text')?.name || columns[0]?.name;
    if (!idField || !(idField in task.fields)) {
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
    if (!idField || !(idField in task.fields)) {
      alert('Cannot delete task: no identifier field');
      return;
    }

    try {
      await apiService.deleteTask(task.fields[idField], idField);
      await loadData();
    } catch (error) {
      console.error('Error deleting task:', error);
      alert('Failed to delete task');
    }
    setContextMenu(null);
  };

  const handleAddNewCategory = async () => {
    if (!newCategoryName.trim() || !newCategoryContext.trim()) return;
    const categoryCol = columns.find(c => c.name === 'category');
    if (!categoryCol) return;

    const newOptionToAdd = { name: newCategoryName, context: newCategoryContext };
    const newOptions = [...categoryCol.options, newOptionToAdd];
    await apiService.updateCategoryOptions(newOptions);
    await loadData();
    setNewCategoryName('');
    setNewCategoryContext('');
  };

  const handleDeleteCategory = async (nameToDelete: string) => {
    const categoryCol = columns.find(c => c.name === 'category');
    if (!categoryCol) return;

    const newOptions = categoryCol.options.filter(opt => {
      const name = typeof opt === 'object' && opt !== null ? opt.name : opt;
      return name !== nameToDelete;
    });

    await apiService.updateCategoryOptions(newOptions);
    await loadData();
  };

  const handleSaveCategoryContext = async () => {
    if (!editingCategory) return;
    const categoryCol = columns.find(c => c.name === 'category');
    if (!categoryCol) return;

    const newOptions = categoryCol.options.map(opt => {
      if (typeof opt === 'object' && opt !== null && opt.name === editingCategory.name) {
        return { ...opt, context: editContext };
      }
      return opt;
    });

    await apiService.updateCategoryOptions(newOptions);
    await loadData();
    setEditingCategory(null);
  };

  const handleRowContextMenu = (e: React.MouseEvent, task: Task) => {
    e.preventDefault();
    setContextMenu({ x: e.clientX, y: e.clientY, task });
  };

  const getColumnWidth = (columnName: string) => {
    if (columnName === 'name') return '40%';
    if (columnName === 'category') return '25%';
    if (columnName === 'status') return '15%';
    return 'auto';
  };

  const categoryCol = columns.find(c => c.name === 'category');

  if (loading) {
    return <div className="d-flex justify-content-center align-items-center vh-100"><h2>Loading...</h2></div>;
  }

  return (
    <div className="container mt-5">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h1>Task Tracker</h1>
        <button className="btn btn-primary" onClick={handleStartAddTask}>
          Add Task
        </button>
      </div>

      <table className="table table-hover align-middle" style={{ tableLayout: 'fixed' }}>
        <thead className="table-light">
          <tr>
            {columns.map(column => (
              <th key={column.name} scope="col" style={{ width: getColumnWidth(column.name) }}>
                <span
                  className={column.name === 'category' ? 'cursor-pointer' : ''}
                  onContextMenu={(e) => {
                    if (column.name === 'category') {
                      e.preventDefault();
                      setShowCategoryMenu({ x: e.clientX, y: e.clientY });
                    }
                  }}
                >
                  {column.name}
                </span>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {isAddingTask && (
            <tr className="table-primary" key="new-task-row">
              {columns.map(column => (
                <td key={column.name}>
                  <FieldRenderer
                    ref={column.name === 'name' ? nameInputRef : null}
                    column={column}
                    value={newTaskFields[column.name]}
                    onChange={(value) => setNewTaskFields({ ...newTaskFields, [column.name]: value })}
                    onKeyDown={column.name === 'name' ? handleNameKeyDown : undefined}
                    disabled={column.name !== 'name'}
                  />
                </td>
              ))}
            </tr>
          )}

          {tasks.map((task, idx) => (
            <tr key={idx} onContextMenu={(e) => handleRowContextMenu(e, task)}>
              {columns.map(column => (
                <td key={column.name}>
                  <FieldRenderer
                    column={column}
                    value={task.fields[column.name]}
                    onChange={(value) => handleUpdateTask(task, column.name, value)}
                  />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>

      {showCategoryMenu && (
        <div ref={categoryMenuRef} className="card shadow-lg" style={{ position: 'fixed', top: showCategoryMenu.y, left: showCategoryMenu.x, width: '350px', zIndex: 1050 }}>
          <div className="card-header">Manage Categories</div>
          <div className="card-body" style={{ maxHeight: '300px', overflowY: 'auto' }}>
            <ul className="list-group list-group-flush">
              {(categoryCol?.options || []).map(opt => {
                const isObject = typeof opt === 'object' && opt !== null;
                const name = isObject ? (opt as CategoryOption).name : opt as string;
                const context = isObject ? (opt as CategoryOption).context : null;

                return (
                  <li key={name} className="list-group-item d-flex justify-content-between align-items-start">
                    <div>
                      <h6 className="mb-1">{name}</h6>
                      {context && <p className="text-muted small mb-0">{context}</p>}
                    </div>
                    <div className="btn-group">
                      {isObject && (
                        <button className="btn btn-link btn-sm" onClick={() => setEditingCategory(opt as CategoryOption)}>Edit</button>
                      )}
                      <button className="btn btn-link btn-sm text-danger" onClick={() => handleDeleteCategory(name)}>Delete</button>
                    </div>
                  </li>
                );
              })}
            </ul>
          </div>
          <div className="card-footer">
            <p className="mb-1 small fw-bold">Add New Category</p>
            <div className="input-group mb-2">
              <input type="text" className="form-control" placeholder="Category Name" value={newCategoryName} onChange={(e) => setNewCategoryName(e.target.value)} />
            </div>
            <div className="input-group mb-2">
              <textarea className="form-control" placeholder="Context for AI" value={newCategoryContext} onChange={(e) => setNewCategoryContext(e.target.value)} />
            </div>
            <button className="btn btn-success btn-sm w-100" onClick={handleAddNewCategory}>Add</button>
          </div>
        </div>
      )}

      {editingCategory && (
        <div className="modal fade show d-block" tabIndex={-1}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title">Edit Context for "{editingCategory.name}"</h5>
                <button type="button" className="btn-close" onClick={() => setEditingCategory(null)}></button>
              </div>
              <div className="modal-body">
                <textarea
                  className="form-control"
                  value={editContext}
                  onChange={(e) => setEditContext(e.target.value)}
                  rows={5}
                  autoFocus
                />
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setEditingCategory(null)}>Cancel</button>
                <button type="button" className="btn btn-primary" onClick={handleSaveCategoryContext}>Save changes</button>
              </div>
            </div>
          </div>
        </div>
      )}

      {contextMenu && (
        <div ref={contextMenuRef} className="dropdown-menu show" style={{ top: contextMenu.y, left: contextMenu.x }}>
          <a className="dropdown-item text-danger" href="#" onClick={(e) => { e.preventDefault(); handleDeleteTask(contextMenu.task); }}>
            Delete Row
          </a>
        </div>
      )}

      {tasks.length === 0 && !isAddingTask && (
        <div className="text-center p-5">
          <p>No tasks yet. Click "Add Task" to get started!</p>
        </div>
      )}
    </div>
  );
}
