import React, { Component, PureComponent } from "react";

export class One extends Component {
  render() {
    return null;
  }
}

export class Two extends React.Component {
  render() {
    return null;
  }
}

export class Three extends PureComponent {
  render() {
    return null;
  }
}

export const Four = class extends Component {
  render() {
    return null;
  }
};
