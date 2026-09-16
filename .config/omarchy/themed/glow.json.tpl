{
  "document": {
    "block_prefix": "\n",
    "block_suffix": "\n",
    "color": "{{ foreground }}",
    "margin": 2
  },
  "block_quote": {
    "indent": 1,
    "indent_token": "│ ",
    "color": "{{ muted }}"
  },
  "paragraph": {},
  "list": {
    "level_indent": 2
  },
  "heading": {
    "block_suffix": "\n",
    "color": "{{ accent }}",
    "bold": true
  },
  "h1": {
    "prefix": " ",
    "suffix": " ",
    "color": "{{ background }}",
    "background_color": "{{ accent }}",
    "bold": true
  },
  "h2": {
    "prefix": "## ",
    "color": "{{ bright_cyan }}",
    "bold": true
  },
  "h3": {
    "prefix": "### ",
    "color": "{{ cyan }}",
    "bold": true
  },
  "h4": {
    "prefix": "#### ",
    "color": "{{ green }}",
    "bold": true
  },
  "h5": {
    "prefix": "##### ",
    "color": "{{ blue }}",
    "bold": true
  },
  "h6": {
    "prefix": "###### ",
    "color": "{{ muted }}",
    "bold": false
  },
  "text": {},
  "strikethrough": {
    "crossed_out": true
  },
  "emph": {
    "color": "{{ light_foreground }}",
    "italic": true
  },
  "strong": {
    "color": "{{ bright_foreground }}",
    "bold": true
  },
  "hr": {
    "color": "{{ muted }}",
    "format": "\n--------\n"
  },
  "item": {
    "block_prefix": "• ",
    "color": "{{ cyan }}"
  },
  "enumeration": {
    "block_prefix": ". ",
    "color": "{{ cyan }}"
  },
  "task": {
    "ticked": "[✓] ",
    "unticked": "[ ] "
  },
  "link": {
    "color": "{{ blue }}",
    "underline": true
  },
  "link_text": {
    "color": "{{ cyan }}",
    "bold": true
  },
  "image": {
    "color": "{{ magenta }}",
    "underline": true
  },
  "image_text": {
    "color": "{{ muted }}",
    "format": "Image: {{.text}} →"
  },
  "code": {
    "prefix": " ",
    "suffix": " ",
    "color": "{{ bright_yellow }}",
    "background_color": "{{ lighter_background }}"
  },
  "code_block": {
    "color": "{{ foreground }}",
    "margin": 2,
    "chroma": {
      "text": {
        "color": "{{ foreground }}"
      },
      "error": {
        "color": "{{ bright_foreground }}",
        "background_color": "{{ red }}"
      },
      "comment": {
        "color": "{{ muted }}",
        "italic": true
      },
      "comment_preproc": {
        "color": "{{ yellow }}"
      },
      "keyword": {
        "color": "{{ magenta }}"
      },
      "keyword_reserved": {
        "color": "{{ magenta }}"
      },
      "keyword_namespace": {
        "color": "{{ magenta }}"
      },
      "keyword_type": {
        "color": "{{ yellow }}"
      },
      "operator": {
        "color": "{{ cyan }}"
      },
      "punctuation": {
        "color": "{{ dark_foreground }}"
      },
      "name": {
        "color": "{{ foreground }}"
      },
      "name_builtin": {
        "color": "{{ red }}"
      },
      "name_tag": {
        "color": "{{ blue }}"
      },
      "name_attribute": {
        "color": "{{ yellow }}"
      },
      "name_class": {
        "color": "{{ bright_foreground }}",
        "underline": true,
        "bold": true
      },
      "name_constant": {
        "color": "{{ yellow }}"
      },
      "name_decorator": {
        "color": "{{ yellow }}"
      },
      "name_exception": {
        "color": "{{ red }}"
      },
      "name_function": {
        "color": "{{ blue }}"
      },
      "name_other": {
        "color": "{{ foreground }}"
      },
      "literal": {
        "color": "{{ green }}"
      },
      "literal_number": {
        "color": "{{ yellow }}"
      },
      "literal_date": {
        "color": "{{ green }}"
      },
      "literal_string": {
        "color": "{{ green }}"
      },
      "literal_string_escape": {
        "color": "{{ magenta }}"
      },
      "generic_deleted": {
        "color": "{{ red }}"
      },
      "generic_emph": {
        "italic": true
      },
      "generic_inserted": {
        "color": "{{ green }}"
      },
      "generic_strong": {
        "bold": true
      },
      "generic_subheading": {
        "color": "{{ muted }}"
      },
      "background": {
        "background_color": "{{ lighter_background }}"
      }
    }
  },
  "table": {},
  "definition_list": {},
  "definition_term": {},
  "definition_description": {
    "block_prefix": "\n🠶 "
  },
  "html_block": {},
  "html_span": {}
}
