# cmp-conventionalcommits

**Alpha — Work in progress**

[Conventional Commits](https://www.conventionalcommits.org) source for [`nvim-cmp`](https://github.com/hrsh7th/nvim-cmp).

Reads your configured scopes from [commitlint](https://commitlint.js.org/#/):

![example_1](https://user-images.githubusercontent.com/9190258/139169092-a44587c8-725c-4296-b2bf-24fb6dbc381a.png)

If you have [Lerna](https://lerna.js.org/), completes your local packages in the scope:

![example_2](https://user-images.githubusercontent.com/9190258/139169114-d6832cab-a123-4a96-a92f-6b84e11f028b.png)

## Setup

Setup in `after/ftplugin/gitcommit.lua`

```lua
require'cmp'.setup.buffer {
  sources = require'cmp'.config.sources(
    {{ name = 'conventionalcommits' }},
    {{ name = 'buffer' }}
  ),
}
```
