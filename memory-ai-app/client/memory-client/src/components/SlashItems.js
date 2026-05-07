import {
  rewriteMemory,
  submitAnswer,
} from "../api/ai";

export const slashItems = [
  {
    group: "结构",
    items: [
      {
        title: "标题",

        command: async ({ editor, range }) => {
          const text = editor.getText();

          const data = await rewriteMemory(
            `为下面内容生成一个标题：\n${text}`
          );

          editor
            .chain()
            .focus()
            .deleteRange(range)
            .insertContent(`<h2>${data.result}</h2>`)
            .run();
        },
      },

      {
        title: "时间线",

        command: async ({ editor, range }) => {
          const text = editor.getText();

          const data = await rewriteMemory(
            `整理成时间线：\n${text}`
          );

          editor
            .chain()
            .focus()
            .deleteRange(range)
            .insertContent(data.result)
            .run();
        },
      },
    ],
  },

  {
    group: "表达",
    items: [
      {
        title: "总结",

        command: async ({ editor }) => {
          const text = editor.getText();

          const data = await rewriteMemory(
            `总结这段内容：\n${text}`
          );

          editor
            .chain()
            .focus()
            .insertContent(`\n🧠 ${data.result}`)
            .run();
        },
      },

      {
        title: "情绪增强",

        command: async ({ editor, range }) => {
          const text = editor.getText();

          const data = await rewriteMemory(
            `增强情绪表达：\n${text}`
          );

          editor
            .chain()
            .focus()
            .deleteRange(range)
            .insertContent(data.result)
            .run();
        },
      },
    ],
  },

  {
    group: "生成",
    items: [
      {
        title: "继续写",

        command: async ({ editor }) => {
          const text = editor.getText();

          const data = await submitAnswer(
            `${text}\n继续写下去`
          );

          editor
            .chain()
            .focus()
            .insertContent(data.result)
            .run();
        },
      },
    ],
  },
];