# Basic nushell configuration
let dark_theme = {
    separator: "#888888"
    leading_trailing_space_bg: { attr: "n" }
    header: { fg: "#5f87af" attr: "b" }
    empty: "#5f87af"
    bool: "#5f87af"
    int: "#5f87af"
    filesize: "#5f87af"
    duration: "#5f87af"
    date: "#5f87af"
    range: "#5f87af"
    float: "#5f87af"
    string: "#5f87af"
    nothing: "#5f87af"
    binary: "#5f87af"
    row_index: { fg: "#888888" attr: "b" }
}

# Use starship prompt if you want (optional)
$env.STARSHIP_SHELL = "nu"
$env.PROMPT_COMMAND = { || starship prompt }
$env.PROMPT_COMMAND_RIGHT = ""

# For prompt performance
$env.PROMPT_INDICATOR = "〉"
$env.PROMPT_INDICATOR_VI_INSERT = "："
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "
