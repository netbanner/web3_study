import {
  useEditor,
  EditorContent,
} from "@tiptap/react";

import StarterKit from "@tiptap/starter-kit";

import Suggestion from "@tiptap/suggestion";

import { Extension } from "@tiptap/core";

import { useEffect } from "react";

import { slashItems } from "./SlashItems";

const SlashCommand = Extension.create({

  name: "slash-command",

  addProseMirrorPlugins() {

    return [

      Suggestion({

        editor: this.editor,

        char: "/",

        items: ({ query }) => {

          return slashItems
            .flatMap(g => g.items)
            .filter(item =>
              item.title.includes(query)
            );

        },

        render: () => {

          let popup;

          return {

            onStart: props => {

              popup =
                document.createElement("div");

              popup.className =
                "slash-menu-popup";

              updatePopup(props);

              document.body.appendChild(
                popup
              );

            },

            onUpdate(props) {

              updatePopup(props);

            },

            onExit() {

              popup.remove();

            },

          };

          function updatePopup(props) {

            popup.innerHTML = "";

            props.items.forEach(item => {

              const div =
                document.createElement("div");

              div.className =
                "slash-item";

              div.innerText =
                item.title;

              div.onclick = () => {

                item.command({
                  editor: props.editor,
                  range: props.range,
                });

              };

              popup.appendChild(div);

            });

            const rect =
              props.clientRect?.();

            if (!rect) return;

            popup.style.position =
              "absolute";

            popup.style.left =
              rect.left + "px";

            popup.style.top =
              rect.bottom + 8 + "px";

            popup.style.background =
              "white";

            popup.style.border =
              "1px solid #eee";

            popup.style.borderRadius =
              "12px";

            popup.style.padding =
              "8px";

            popup.style.width =
              "240px";

            popup.style.boxShadow =
              "0 10px 40px rgba(0,0,0,0.12)";

            popup.style.zIndex =
              99999;

          }

        },

      }),

    ];

  },

});

export default function Editor({
  content,
  setContent,
}) {

  const editor = useEditor({

    extensions: [

      StarterKit,

      SlashCommand,

    ],

    content: `
      <h1>我的记忆</h1>
      <p>输入 / 使用 AI 命令</p>
    `,

    onUpdate: ({ editor }) => {

      setContent(
        editor.getHTML()
      );

    },

  });

  // ✅ 关键：同步 content
  useEffect(() => {

    if (
      editor &&
      content
    ) {

      editor.commands.setContent(
        content
      );

    }

  }, [content, editor]);

  return (

    <div>

      <EditorContent
        editor={editor}
      />

    </div>

  );

}