import {
  Button as AriaButton,
  ComboBox as AriaComboBox,
  Input,
  Label,
  ListBox,
  ListBoxItem,
  Popover,
} from "react-aria-components";

type ComboBoxItem = { id: string; label: string };

type ComboBoxProps = {
  testId: string;
  label: string;
  items: ComboBoxItem[];
  selectedKey?: string | null;
  onSelectionChange?: (key: string) => void;
  placeholder?: string;
};

export function ComboBox({
  testId,
  label,
  items,
  selectedKey,
  onSelectionChange,
  placeholder,
}: ComboBoxProps) {
  return (
    <AriaComboBox
      selectedKey={selectedKey ?? null}
      onSelectionChange={(key) => {
        if (key != null) onSelectionChange?.(String(key));
      }}
      className="block text-sm font-medium text-slate-700"
    >
      <Label>{label}</Label>
      <div className="mt-1 flex">
        <Input
          data-testid={testId}
          placeholder={placeholder}
          className="w-full rounded-l-card border border-slate-300 px-3 py-2 outline-offset-2 focus-visible:outline-2"
        />
        <AriaButton
          data-testid={`${testId}.toggle`}
          className="rounded-r-card border border-l-0 border-slate-300 px-3 py-2 outline-offset-2 focus-visible:outline-2"
        >
          <span aria-hidden="true">▼</span>
        </AriaButton>
      </div>
      <Popover className="rounded-card border border-slate-200 bg-surface shadow-card">
        <ListBox items={items} className="p-1">
          {(item: ComboBoxItem) => (
            <ListBoxItem
              id={item.id}
              textValue={item.label}
              data-testid={`${testId}.option.${item.id}`}
              className="cursor-pointer rounded-card px-3 py-2 outline-offset-2 focus-visible:outline-2"
            >
              {item.label}
            </ListBoxItem>
          )}
        </ListBox>
      </Popover>
    </AriaComboBox>
  );
}
