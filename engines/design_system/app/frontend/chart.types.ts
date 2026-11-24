export type ChartSeriesType = "pie";

export type ChartPoint = {
  label: string;
  value: number;
  date?: string;
};

export type ChartSeries = {
  name: string;
  type: ChartSeriesType;
  data: ChartPoint[];
};

export type ChartOption = {
  series: ChartSeries[];
};

export type ChartProps = {
  testId: string;
  ariaLabel: string;
  description?: string;
  option: ChartOption;
};

export type ChartTheme = {
  color: string[];
  backgroundColor: string;
  textStyle: { color: string };
};

export type ChartLabels = {
  empty: string;
  error: string;
  showTable: string;
  hideTable: string;
  tableCaption: string;
  series: string;
  label: string;
  date: string;
  value: string;
};

export type ChartImplProps = ChartProps & {
  locale: string;
  timeZone: string;
  labels: ChartLabels;
};
