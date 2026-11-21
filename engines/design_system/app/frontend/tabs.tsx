import type { ReactNode } from "react";

import { Tab, TabList, TabPanel, Tabs as AriaTabs } from "react-aria-components";

type TabDefinition = { id: string; label: string; content: ReactNode };

type TabsProps = {
  testId: string;
  label: string;
  tabs: TabDefinition[];
  selectedKey?: string | null;
  onSelectionChange?: (key: string) => void;
};

export function Tabs({ testId, label, tabs, selectedKey, onSelectionChange }: TabsProps) {
  return (
    <AriaTabs
      selectedKey={selectedKey ?? undefined}
      onSelectionChange={(key) => {
        if (key != null) onSelectionChange?.(String(key));
      }}
    >
      <TabList aria-label={label} className="flex gap-2 border-b border-slate-200">
        {tabs.map((tab) => (
          <Tab
            key={tab.id}
            id={tab.id}
            data-testid={`${testId}.tab.${tab.id}`}
            className="rounded-t-card px-3 py-2 outline-offset-2 focus-visible:outline-2 data-[selected]:border-b-2 data-[selected]:border-primary data-[selected]:font-semibold"
          >
            {tab.label}
          </Tab>
        ))}
      </TabList>
      {tabs.map((tab) => (
        <TabPanel
          key={tab.id}
          id={tab.id}
          data-testid={`${testId}.panel.${tab.id}`}
          className="pt-4 outline-none"
        >
          {tab.content}
        </TabPanel>
      ))}
    </AriaTabs>
  );
}
