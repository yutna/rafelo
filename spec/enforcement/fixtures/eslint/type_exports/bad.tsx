export type Name = string;

export interface Shape {
  name: string;
}

export default interface DefaultShape {
  name: string;
}

export type { Name as Renamed } from "./types";
export { type Shape as ShapeType } from "./types";
export type * from "./types";
