if vim.g.cmp_conventionalcommits_source_id ~= nil then
    require('cmp').unregister_source(vim.g.cmp_conventionalcommits_source_id)
end
vim.g.cmp_conventionalcommits_source_id = require('cmp').register_source('conventionalcommits', require('cmp-conventionalcommits').new())
