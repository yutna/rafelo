import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { PageHeading } from "./page_heading";

describe("PageHeading", () => {
  it("renders the title as the page heading", () => {
    const title = "Rafelo";
    render(<PageHeading title={title} />);

    const heading = screen.getByRole("heading", { level: 1, name: title });
    expect(heading).toHaveTextContent("Rafelo");
  });
});
