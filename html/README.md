
# HTML

This submodule is a small DSL for HTML code generation.

## Usage

### Basics

By calling the module with `html.$ELEM` you can generate code for any valid html5 tag.
For example:

```lua
local h = require("lutils").html

local page = h.html {
    lang="en-US"
    h.head {
        h.meta { charset="utf-8" },
        h.meta { name="viewport", content="width=device-width" },
        h.title { "My test page" },
    },
    h.body {
        h.img { src="images/firefox-icon.png", alt="My test image" },
    },
}

print(h.render(page))
```

When creating this structure, the static portions of your HTML will be pre-rendered as much as
possible into static fragments of HTML.

By called `html.render` on our structure we will generate the following HTML:

```html
<html lang="en-US">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width" />
    <title>My test page</title>
  </head>
  <body>
    <img src="images/firefox-icon.png" alt="My test image" />
  </body>
</html>
```

By default `render` will return a string of the rendered HTML, however we can pass in our
own function to process fragments as they're rendered. For example if we were processing a
request and wanted to write data to the output buffer as soon as possible we might define
our own function `WriteBuf` and use it as such:

```lua
h.render(page, WriteBuf)
```

### Dynamic Rendering

Generating static pages is well and good, but we can also use functions to run arbitrary code.

```lua
local message = h.div {
    h.p { "Hello ", function(opts) return opts.name or "World" end, "!" }
}

print(h.render(message))
print(h.render(message, nil, { name = "Foo" }))
```

Will generate

```html
<div><p>Hello World!</p></div>
```

and

```html
<div><p>Hello Foo!</p></div>
```

And the best part is that only the dynamic portions of the fragment will need to be rendered, the
rest will have been pre-rendered! Internally, `message` will be represented as such:

```lua
{"<div><p>Hello ", function: 0x1000800ca800, "!</p></div>"}
```

The only stipulation for functions in the templates is that they must return either a string or
another fragment. For example:


```lua
local message = h.div {
    function(opts)
        if opts.arriving then
            return h.p { "Hello ", opts.name, "!" }
        else
            return h.p { "Goodbye ", opts.name, "!"}
        end
    end
}
```

To facillitate easier dynamic generation a few helpers are provided. To demonstrate: here's
a more involved template:

```lua
local card = h.div {
   style = { "transition-delay: ", h.get("delay", 100), "ms" },
   hx_get = h.format("/game/%s/%s", { "system", "title" }),
   hx_target = "#game",
   hx_swap = "innerHTML",
   hx_replace_url = "true",
   ["@click"] = "show_game = true, show_catalog = false",

   h.div {
      class = "title",
      h.get("title", "N/A"),
   },
   h.img {
      class = "art",
      src = h.get("url", "https://placehold.co/600x400"),
      alt = h.get("title", "Placeholder Image"),
   },
}

render(card, nil, { title = "Warcraft", System = "DOS", delay = 150 })
```

This will create the following HTML

```html
<div
  style="transition-delay: 150ms"
  hx-get="/game/DOS/Warcraft"
  hx-target="#game"
  hx-swap="innerHTML"
  hx-replace-url="true"
  @click="show_game = true, show_catalog = false"
>
  <div class="title">Warcraft</div>
  <img class="art" src="https://placeholder.com" alt="Warcraft" />
</div>
```

Here we can see the helpers `get` and `format` in use.
 - `get` lets us fetch a parameter from `opts` during rendering and set a fallback.
 - `format` is similar but lets us format a string using multiple parameters. Currently does not support fallbacks.



