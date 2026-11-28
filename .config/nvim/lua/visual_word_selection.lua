local M = {}

function M.setup()
  vim.g.VM_default_mappings = 0
  vim.g.VM_live_editing = 1
  vim.g.VM_quit_after_leaving_insert_mode = 1
  vim.g.VM_set_statusline = 0
  vim.g.VM_maps = {
    ["Find Under"] = "",
    ["Find Subword Under"] = "",
    ["Find Next"] = "[c",
    ["Goto Prev"] = "",
    ["Goto Next"] = "",
  }

  local group = vim.api.nvim_create_augroup("VisualWordSelection", { clear = true })
  local backspace_maps = {}
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "visual_multi_start",
    callback = function(args)
      -- Attach autopairs before Visual Multi takes over the buffer's Backspace key.
      require("nvim-autopairs")
      local mapping = vim.fn.maparg("<BS>", "i", false, true)
      if mapping.buffer == 1 and mapping.desc == "autopairs delete" then
        backspace_maps[args.buf] = mapping
        vim.keymap.del("i", "<BS>", { buffer = args.buf })
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "visual_multi_exit",
    callback = function(args)
      local mapping = backspace_maps[args.buf]
      if mapping then
        vim.fn.mapset(mapping)
        backspace_maps[args.buf] = nil
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "visual_multi_mappings",
    callback = function(args)
      vim.keymap.set("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          vim.fn["vm#commands#find_next"](0, 0)
        end
      end, { buffer = args.buf, nowait = true, desc = "Add next exact word selection" })

      vim.keymap.set("n", "c", function()
        local changedtick = vim.b.changedtick
        vim.cmd("call b:VM_Selection.Edit.change(g:Vm.extend_mode, v:count1, v:register, 0)")
        if changedtick == vim.b.changedtick then
          return
        end

        -- Keep deleting the selections and typing the replacement in one undo entry.
        local sequence = vim.fn.undotree().seq_cur
        vim.api.nvim_create_autocmd({ "InsertCharPre", "InsertLeave" }, {
          group = group,
          buffer = args.buf,
          callback = function(event)
            vim.api.nvim_del_autocmd(event.id)
            if event.event == "InsertCharPre" and vim.fn.undotree().seq_cur == sequence then
              vim.cmd.undojoin()
            end
          end,
        })
      end, { buffer = args.buf, nowait = true, desc = "Change multiple selections" })
    end,
  })

  vim.keymap.set("x", "[c", function()
    if vim.wo.diff then
      vim.cmd.normal({ "[c", bang = true })
      return
    end
    if vim.fn.mode() ~= "v" then
      return
    end

    local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."))
    local word = lines[1]
    if #lines ~= 1 or not word or vim.fn.match(word, [[\m^\k\+$]]) < 0 then
      return
    end

    local pattern = [[\C\m\<\V]] .. vim.fn.escape(word, "\\") .. [[\m\>]]
    if vim.fn.search(pattern, "ncw") == 0 then
      return
    end

    -- Start the session before yanking so the plugin records the original registers.
    vim.cmd("call vm#init_buffer(1)")
    vim.cmd("silent keepjumps noautocmd normal! y")
    vim.cmd("call vm#commands#find_under(1, 1)")
    -- Seed the search explicitly so it retains word boundaries and case sensitivity.
    vim.cmd("call b:VM_Selection.Search.join([" .. vim.fn.string(pattern) .. "])")
    vim.fn["vm#commands#find_next"](0, 0)
  end, { desc = "Add next exact word selection" })
end

return M
