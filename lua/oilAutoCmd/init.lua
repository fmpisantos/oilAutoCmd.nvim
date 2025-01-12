local M = {}

local function file_matches_pattern(filepath, pattern)
    local matches = vim.fn.glob(pattern)
    vim.print(string.format("Matching %s with %s (%s)", filepath, matches, tostring(vim.fn.match(filepath, matches))))
    return vim.fn.match(filepath, matches) ~= -1
end

local function file_matches_patterns(filepath, patterns)
    for _, pattern in ipairs(patterns) do
        if file_matches_pattern(filepath, pattern) then
            return true
        end
    end
    return false
end

M.get_actual_path = function(path)
    return path:gsub("file://", ""):gsub("oil://", "")
end

M.setup = function(deleteArgs, moveArgs)
    M.fileDeleteCallback, M.fileDeletePattern = deleteArgs.func, deleteArgs.pattern
    M.fileMoveCallback, M.fileMovePattern = moveArgs.func, moveArgs.pattern

    if not M.fileDeletePattern then
        M.fileDeletePattern = {}
    end

    if not M.fileMovePattern then
        M.fileMovePattern = {}
    end

    vim.api.nvim_create_autocmd("User", {
        pattern = "OilActionsPost",
        callback = function(args)
            for _, action in ipairs(args.data.actions) do
                if action.entry_type ~= "file" then
                    goto continue
                end
                if action.type == "delete" then
                    local path = M.get_actual_path(action.url);
                    if M.fileDeletePattern and #M.fileDeletePattern then
                        if file_matches_patterns(path, M.fileDeletePattern) then
                            M.fileDeleteCallback(path)
                        end
                    else
                        M.fileDeleteCallback(path)
                    end
                elseif action.type == "move" then
                    local dest = M.get_actual_path(action.dest_url);
                    local src = M.get_actual_path(action.src_url);
                    if M.fileMovePattern and #M.fileMovePattern then
                        if file_matches_patterns(dest, M.fileMovePattern) or file_matches_patterns(src, M.fileMovePattern) then
                            M.fileMoveCallback(src, dest)
                        end
                    else
                        M.fileMoveCallback(src, dest)
                    end
                end
                ::continue::
            end
        end
    })
end

return M;
