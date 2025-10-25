export type ColumnType = "text" | "select" | "multiselect" | "date";

export type Column = {
  name: string;
  type: ColumnType;
  options: string[];
  order: number;
};

export type Task = {
  fields: Record<string, any>;
  created_at: string;
};
