export function blogTemplate(markdown) {
  return `
<html>
<head>
<meta charset="UTF-8">
<style>
body { font-family: Arial; max-width: 800px; margin: auto; padding: 40px; }
</style>
</head>
<body>
<div id="app"></div>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<script>
document.getElementById("app").innerHTML =
marked.parse(\`${markdown.replace(/`/g, "\\`")}\`);
</script>
</body>
</html>
`;
}