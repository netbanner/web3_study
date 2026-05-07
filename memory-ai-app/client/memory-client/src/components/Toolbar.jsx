import { useEffect, useState } from "react";

export default function Toolbar({
  onRewrite,
}) {
  const [show, setShow] =
    useState(false);

  const [position, setPosition] =
    useState({
      top: 0,
      left: 0,
    });

  useEffect(() => {
    function handleSelection() {
      const selection =
        window.getSelection();

      if (!selection.rangeCount)
        return;

      const text =
        selection.toString();

      if (text.length > 0) {
        const rect =
          selection
            .getRangeAt(0)
            .getBoundingClientRect();

        setPosition({
          top:
            rect.top +
            window.scrollY -
            50,

          left:
            rect.left +
            window.scrollX,
        });

        setShow(true);
      } else {
        setShow(false);
      }
    }

    document.addEventListener(
      "selectionchange",
      handleSelection
    );

    return () =>
      document.removeEventListener(
        "selectionchange",
        handleSelection
      );
  }, []);

  if (!show) return null;

  return (
    <div
      style={{
        position: "absolute",

        top: position.top,

        left: position.left,

        background: "black",

        color: "white",

        borderRadius: "12px",

        padding: "8px 12px",

        display: "flex",

        gap: 8,

        zIndex: 999,
      }}
    >
      <button onClick={onRewrite}>
        ✨ 改写
      </button>
    </div>
  );
}