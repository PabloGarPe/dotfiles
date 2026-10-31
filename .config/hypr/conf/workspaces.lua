--------------------
---- WORKSPACES ----
--------------------

-- Ref https://wiki.hypr.land/configuring/core/rules/workspace-rules/
-- Workspaces 1-5 en el monitor principal (DP-1), 6-10 en el secundario (HDMI-A-1)
for i = 1, 10 do
    hl.workspace_rule({
        workspace  = tostring(i),
        monitor    = i <= 5 and "DP-1" or "HDMI-A-1",
        default    = (i == 1 or i == 6),
        persistent = true,
    })
end

-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
