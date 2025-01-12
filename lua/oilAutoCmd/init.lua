local M = {}

local function file_matches_pattern(filepath, pattern)
    local matches = vim.fn.glob(pattern)
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
    M.fileDeleteCallback, M.fileDeletePattern              = deleteArgs.func, deleteArgs.pattern
    M.fileMoveCallback, M.fileMovePattern, M.fileMoveOnEnd = moveArgs.func, moveArgs.pattern, moveArgs.on_end

    if not M.fileDeletePattern then
        M.fileDeletePattern = {}
    end

    if not M.fileMovePattern then
        M.fileMovePattern = {}
    end

    vim.api.nvim_create_autocmd("User", {
        pattern = "OilActionsPost",
        callback = function(args)
            local moved = false;
            for _, action in ipairs(args.data.actions) do
                if action.entry_type ~= "file" then
                    goto continue
                end
                if action.type == "delete" then
                    local path = M.get_actual_path(action.url);
                    if M.fileDeletePattern and #M.fileDeletePattern > 0 then
                        if file_matches_patterns(path, M.fileDeletePattern) then
                            M.fileDeleteCallback(path)
                        end
                    else
                        M.fileDeleteCallback(path)
                    end
                elseif action.type == "move" then
                    local dest = M.get_actual_path(action.dest_url);
                    local src = M.get_actual_path(action.src_url);
                    if M.fileMovePattern and #M.fileMovePattern > 0 then
                        if file_matches_patterns(dest, M.fileMovePattern) or file_matches_patterns(src, M.fileMovePattern) then
                            M.fileMoveCallback(src, dest)
                            moved = true;
                        end
                    else
                        M.fileMoveCallback(src, dest)
                        moved = true;
                    end
                end
                ::continue::
            end
            if moved and M.fileMoveOnEnd then
                M.fileMoveOnEnd()
            end
        end
    })
end

return M;
