import axios from 'axios';
import type { Column, Task } from './types';

const API_BASE_URL = '';

export class ApiService {
  // Column methods
  async initDefaultColumns() {
    const response = await axios.post(`${API_BASE_URL}/walker/init_default_columns`);
    return response.data;
  }

  async getColumns(): Promise<Column[]> {
    const response = await axios.post(`${API_BASE_URL}/walker/get_columns`);
    const columns = response.data.reports[0]?.columns || [];
    return columns.map((column: any) => ({ ...column, type: column.type.toLowerCase() }));
  }

  async addColumn(column: Omit<Column, 'order'>) {
    const response = await axios.post(`${API_BASE_URL}/walker/add_column`, column);
    return response.data;
  }

  async updateColumn(name: string, updates: { new_type?: string; new_options?: string[] }) {
    const response = await axios.post(`${API_BASE_URL}/walker/update_column`, {
      name,
      ...updates
    });
    return response.data;
  }

  async deleteColumn(name: string) {
    const response = await axios.post(`${API_BASE_URL}/walker/delete_column`, { name });
    return response.data;
  }

  // Task methods
  async getTasks(): Promise<Task[]> {
    const response = await axios.post(`${API_BASE_URL}/walker/get_tasks`);
    return response.data.reports[0]?.tasks || [];
  }

  async addTask(fields: Record<string, any>) {
    const response = await axios.post(`${API_BASE_URL}/walker/add_task`, { fields });
    return response.data;
  }

  async updateTask(taskId: string, fields: Record<string, any>, idField: string = 'assignment') {
    const response = await axios.post(`${API_BASE_URL}/walker/update_task`, {
      task_id: taskId,
      id_field: idField,
      fields
    });
    return response.data;
  }

  async deleteTask(taskId: string, idField: string = 'assignment') {
    const response = await axios.post(`${API_BASE_URL}/walker/delete_task`, {
      task_id: taskId,
      id_field: idField
    });
    return response.data;
  }

  async suggestCategory(taskName: string): Promise<string | null> {
    const response = await axios.post(`${API_BASE_URL}/walker/suggest_category`, { task_name: taskName });
    if (response.data.reports[0]?.success) {
      return response.data.reports[0].category;
    }
    return null;
  }
}
