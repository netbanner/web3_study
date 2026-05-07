import {
  Type,
  List,
  Heart,
  PenLine,
} from "lucide-react";

const icons = {
  标题: Type,
  时间线: List,
  总结: PenLine,
  情绪增强: Heart,
};

export default function SlashMenu({
  groups,
  command,
}) {
  return (
    <div className="slash-menu">
      {groups.map((group, gi) => (
        <div key={gi}>
          <div
            style={{
              fontSize: 12,
              color: "#888",
              margin: "10px 0",
            }}
          >
            {group.group}
          </div>

          {group.items.map((item, i) => {
            const Icon =
              icons[item.title];

            return (
              <div
                key={i}
                onClick={() =>
                  command(item)
                }
                style={{
                  display: "flex",

                  alignItems: "center",

                  gap: 10,

                  padding: 10,

                  borderRadius: 10,

                  cursor: "pointer",
                }}
              >
                {Icon && <Icon size={18} />}

                <div>{item.title}</div>
              </div>
            );
          })}
        </div>
      ))}
    </div>
  );
}