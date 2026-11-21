import {
  Button as AriaButton,
  Menu as AriaMenu,
  MenuItem,
  MenuTrigger,
  Popover,
} from "react-aria-components";

type MenuItemDefinition = { id: string; label: string };

type MenuProps = {
  testId: string;
  label: string;
  items: MenuItemDefinition[];
  onAction: (id: string) => void;
};

export function Menu({ testId, label, items, onAction }: MenuProps) {
  return (
    <MenuTrigger>
      <AriaButton
        data-testid={testId}
        className="rounded-card border border-slate-300 px-3 py-2 outline-offset-2 focus-visible:outline-2"
      >
        {label}
      </AriaButton>
      <Popover className="rounded-card border border-slate-200 bg-surface shadow-card">
        <AriaMenu onAction={(key) => onAction(String(key))} className="p-1 outline-none">
          {items.map((item) => (
            <MenuItem
              key={item.id}
              id={item.id}
              data-testid={`${testId}.item.${item.id}`}
              className="cursor-pointer rounded-card px-3 py-2 outline-offset-2 focus-visible:outline-2"
            >
              {item.label}
            </MenuItem>
          ))}
        </AriaMenu>
      </Popover>
    </MenuTrigger>
  );
}
