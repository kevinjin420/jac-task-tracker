export type ColumnType = "text" | "select" | "multiselect" | "date";

export type CategoryOption = {
  name: string;
  context: string;
};

export type Column = {
  name: string;
  type: ColumnType;
  options: (string | CategoryOption)[];
  order: number;
};

export type Task = {
  fields: Record<string, any>;
  created_at: string;
};
