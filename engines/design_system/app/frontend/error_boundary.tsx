import { Component } from "react";
import type { ErrorInfo, ReactNode } from "react";

type Props = {
  testId: string;
  title: string;
  homeLabel: string;
  retryLabel: string;
  homeHref: string;
  resetKey: string;
  requestId?: string;
  traceId?: string;
  reporter: (error: Error, info: ErrorInfo, context: { requestId?: string; traceId?: string }) => void;
  children: ReactNode;
};

type State = { failed: boolean; error?: Error };

export class ErrorBoundary extends Component<Props, State> {
  state: State = { failed: false };
  private heading = null as HTMLHeadingElement | null;

  static getDerivedStateFromError(error: Error): State {
    return { failed: true, error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    this.props.reporter(error, info, { requestId: this.props.requestId, traceId: this.props.traceId });
    this.heading?.focus();
  }

  componentDidUpdate(previous: Props) {
    if (previous.resetKey !== this.props.resetKey && this.state.failed) {
      this.setState({ failed: false, error: undefined });
    }
  }

  render() {
    if (this.state.failed) {
      return (
        <section role="alert" data-testid={this.props.testId} className="mx-auto max-w-xl px-6 py-24">
          <h1 ref={(node) => { this.heading = node; }} tabIndex={-1} className="text-2xl font-semibold">{this.props.title}</h1>
          {this.props.requestId ? <p className="mt-2 text-sm text-slate-600">{this.props.requestId} · {this.props.traceId}</p> : null}
          <button type="button" onClick={() => this.setState({ failed: false })} className="mt-4 rounded-card bg-muted px-4 py-2">{this.props.retryLabel}</button>
          <a href={this.props.homeHref} className="mt-4 ml-4 inline-block underline">{this.props.homeLabel}</a>
        </section>
      );
    }
    return this.props.children;
  }
}
