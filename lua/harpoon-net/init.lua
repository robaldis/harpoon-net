local Path = require("plenary.path")
local ts_utils = require("nvim-treesitter.ts_utils")


local data_path = vim.fn.stdpath("data")

local cache_config = string.format("%s/harpoon-net.json", data_path)

local config = {
    tests = {}
}
index = 1


local M = {}

local function i(value)
    print(vim.inspect(value))
end


function M.save()
    Path:new(cache_config):write(vim.fn.json_encode(config), "w")
end

local function read_config(local_config)
    return vim.json.decode(Path:new(local_config):read())
end

function M.setup()
    local ok, c_config = pcall(read_config, cache_config)

    if not ok then
        c_config = {
            tests = {}
        }
    end

    -- Plugin config needs to be loaded in when we have some config values, 
    -- currently this is just all of the data created while using the plugin

    config = c_config
end

local function get_master_node()
    local node = ts_utils.get_node_at_cursor()
    if node == nil then
        error("No treesitter parser found.")
    end
    return node
end

local function get_function_name()

    local bufnr = vim.api.nvim_get_current_buf()
    local node = get_master_node()
    local parent = node:parent()

    while parent do
        if parent:type() == 'method_declaration' then
            break
        end
        parent = parent:parent()
    end

    if not parent then return "" end

    for local_node in parent:iter_children() do
        if (local_node:type() == "identifier") then
            node = local_node
        end
    end

    local start_r, start_c = node:start()
    local end_r, end_c = node:end_()

    local name = vim.api.nvim_buf_get_text(bufnr, start_r, start_c, end_r, end_c, {})[1]
    return name
end

function M.add_test()
    -- Do we want to get more than the test name. Some tests might have the same
    -- name but be in different classes
    test_name = get_function_name()
    config.tests[index] = test_name
    index = index + 1
end

function M.print_config()
    i(config)
end


M.setup()

return M
