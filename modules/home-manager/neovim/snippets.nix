{...}: {
  xdg.configFile."nvim/snippets/global.json".text = builtins.toJSON {
    log = {
      prefix = "log";
      body = ["console.log({$1);"];
      description = "Log output to console";
    };
    "arrow function" = {
      prefix = "af";
      body = ["const $1 = ($2) => {" "  $3" "}"];
      description = "Arrow function";
    };
    "async function" = {
      prefix = "asf";
      body = ["async function $1() {\n" "  $2" "\n}"];
      description = "Async arrow function";
    };
    "react component" = {
      prefix = "rc";
      description = "React functional component";
      body = [
        "type $1Props = {};"
        ""
        "export function $1(props: $1Props) {"
        "  return ("
        "    <div>"
        "      $2"
        "    </div>"
        "  );"
        "}"
      ];
    };
  };
}
