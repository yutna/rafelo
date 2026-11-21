import {
  Button as AriaButton,
  Label,
  ListBox,
  ListBoxItem,
  Popover,
  Select as AriaSelect,
  SelectValue,
} from "react-aria-components";

type SelectItem = { id: string; label: string };

type SelectProps = {
  testId: string;
  label: string;
  items: SelectItem[];
  selectedKey?: string | null;
  onSelectionChange?: (key: string) => void;
  placeholder?: string;
};

export function Select({
  testId,
  label,
  items,
  selectedKey,
  onSelectionChange,
  placeholder,
}: SelectProps) {
  return (
    <AriaSelect
      selectedKey={selectedKey ?? null}
      onSelectionChange={(key) => {
        if (key != null) onSelectionChange?.(String(key));
      }}
      placeholder={placeholder}
      className="block text-sm font-medium text-slate-700"
    >
      <Label>{label}</Label>
      <AriaButton
        data-testid={testId}
        className="mt-1 flex w-full items-center justify-between rounded-card border border-slate-300 px-3 py-2 text-left outline-offset-2 focus-visible:outline-2"
      >
        <SelectValue />
        <span aria-hidden="true">▼</span>
      </AriaButton>
      <Popover className="rounded-card border border-slate-200 bg-surface shadow-card">
        <ListBox items={items} className="p-1">
          {(item: SelectItem) => (
            <ListBoxItem
              id={item.id}
              data-testid={`${testId}.option.${item.id}`}
              className="cursor-pointer rounded-card px-3 py-2 outline-offset-2 focus-visible:outline-2"
            >
              {item.label}
            </ListBoxItem>
          )}
        </ListBox>
      </Popover>
    </AriaSelect>
  );
}
