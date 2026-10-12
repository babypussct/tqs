local tunjun = fk.CreateSkill {
  name = "ol_fd__tunjun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_fd__tunjun"] = "屯军",
  [":ol_fd__tunjun"] = "锁定技，每轮开始时，若你的体力上限大于1，你减1点体力上限，然后摸X张牌（X为你的体力上限）。",

  ["$ol_fd__tunjun1"] = "屯安邑之地，慑山东之贼。",
  ["$ol_fd__tunjun2"] = "长安丰饶，当以军养军。",
}

tunjun:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(tunjun.name) and player.maxHp > 1
  end,
  on_use = function (self, event, target, player, data)
    player.room:changeMaxHp(player, -1)
    if not player.dead then
      player:drawCards(player.maxHp, tunjun.name)
    end
  end,
})

return tunjun
