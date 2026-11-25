import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({
  post: vi.fn(),
  setData: vi.fn(),
}));

vi.mock("@inertiajs/react", () => ({
  Head: () => null,
  useForm: () => ({
    data: { email: "", password: "" },
    setData: inertia.setData,
    post: (url: string) => {
      inertia.post(url);
    },
    processing: false,
    errors: {},
  }),
}));

import SignIn from "./new";

const props = {
  auth: { viewer: null },
  trace: { requestId: "request-1", traceId: "trace-1" },
  app: {
    name: "Rafelo",
    locale: "en",
    locales: ["en", "th"],
    localeHrefs: [
      { locale: "en", href: "/en/sign_in" },
      { locale: "th", href: "/th/sign_in" },
    ],
    signInHref: "/en/sign_in",
    timeZone: "Asia/Bangkok",
  },
  nav: [],
  errors: {},
  data: { error: null, formHref: "/en/sign_in" },
  meta: { csrfToken: "token" },
  query: {},
  pagination: null,
  can: {},
};

describe("SignIn page", () => {
  beforeEach(() => {
    inertia.post.mockClear();
    inertia.setData.mockClear();
  });

  it("submits through Inertia to the URL from props", () => {
    render(<SignIn {...props} />);

    fireEvent.submit(screen.getByTestId("signin.submit").closest("form") as HTMLFormElement);

    expect(inertia.post).toHaveBeenCalledWith("/en/sign_in");
  });

  it("focuses the server error summary after a failed submit", async () => {
    const { rerender } = render(<SignIn {...props} />);

    fireEvent.submit(screen.getByTestId("signin.submit").closest("form") as HTMLFormElement);
    rerender(
      <SignIn {...props} data={{ error: "Wrong email or password", formHref: "/en/sign_in" }} />,
    );

    await waitFor(() => expect(screen.getByTestId("signin.error")).toHaveFocus());
  });

  it("does not render a raw CSRF hidden field", () => {
    render(<SignIn {...props} />);

    expect(screen.queryByTestId("signin.csrf")).not.toBeInTheDocument();
  });
});
