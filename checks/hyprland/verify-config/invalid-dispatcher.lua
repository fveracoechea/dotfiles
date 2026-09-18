-- Parser fixture: a string is not a dispatcher; hl.bind must reject this
-- (verified against v0.55.4: "dispatcher must be a dispatcher ... or a lua
-- function"), so the parser check expects a nonzero exit.
hl.bind("SUPER + W", "killactive")
