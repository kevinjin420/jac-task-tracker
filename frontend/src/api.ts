import axios from 'axios';
import type { Column, Task, CategoryOption } from './types';

const API_BASE_URL = '';

export class ApiService {
  // Column methods
  async getColumns(): Promise<Column[]> {
    const response = await axios.post(`${API_BASE_URL}/walker/get_columns`);
    const columns = response.data.reports[0]?.columns || [];
    return columns.map((column: any) => ({ ...column, type: column.type.toLowerCase() }));
  }

  async updateCategoryOptions(newOptions: CategoryOption[]) {
    const response = await axios.post(`${API_BASE_URL}/walker/update_category_options`, {
      new_options: newOptions
    });
    return response.data;
  }

  // Task methods
  async getTasks(): Promise<Task[]> {
    const response = await axios.post(`${API_BASE_URL}/walker/get_tasks`);
    return response.data.reports[0]?.tasks || [];
  }

  async addTask(taskName: string): Promise<Task> {
    const response = await axios.post(`${API_BASE_URL}/walker/add_task`, {
      task_name: taskName
    });
    const report = response.data.reports[0];
    if (!report.success) {
      throw new Error(report.message || 'Failed to add task with AI category');
    }
    return report.task;
  }

  async updateTask(taskId: string, fields: Record<string, any>, idField: string = 'name') {
    const response = await axios.post(`${API_BASE_URL}/walker/update_task`, {
      task_id: taskId,
      id_field: idField,
      fields
    });
    return response.data;
  }

  async deleteTask(taskId: string, idField: string = 'name') {
    const response = await axios.post(`${API_BASE_URL}/walker/delete_task`, {
      task_id: taskId,
      id_field: idField
    });
    return response.data;
  }
}
