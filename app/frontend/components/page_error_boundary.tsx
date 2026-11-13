import { Component } from "react";
import type { ErrorInfo, ReactNode } from "react";

type Props = { children: ReactNode };
type State = { failed: boolean };

export class PageErrorBoundary extends Component<Props, State> {
  state: State = { failed: false };

  static getDerivedStateFromError(): State {
    return { failed: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    void fetch("/core/client_errors", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: error.message, componentStack: info.componentStack }),
    });
  }

  render() {
    if (this.state.failed) {
      return (
        <div role="alert" data-testid="page-error" className="mx-auto max-w-xl px-6 py-24">
          <h1 className="text-2xl font-semibold">Something went wrong.</h1>
          <a href="/" className="mt-4 inline-block underline">Go home</a>
        </div>
      );
    }
    return this.props.children;
  }
}
