local mouFujian = fk.CreateSkill {
  name = "mobile__fujian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__fujian"] = "伏间",
  [":mobile__fujian"] = "锁定技，结束阶段，你随机观看一名其他角色的X张手牌（X为手牌数最少的角色的手牌数）。",

  ["$mobile__fujian1"] = "以上智行间，则大功可成！",
  ["$mobile__fujian2"] = "五间之法，吾尽知而可用。",
}

mouFujian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mouFujian.name) and
      player.phase == Player.Finish and
      #player.room.alive_players > 1 and
      table.every(player.room.alive_players, function(p)
        return not p:isKongcheng()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getHandcardNum()
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= player then
        x = math.min(x, p:getHandcardNum())
        table.insert(targets, p)
      end
    end
    local to = room:tableRandomPick(targets)
    room:doIndicate(player, { to })
    room:viewCards(player, {
      cards = room:tableRandomPick(to:getCardIds("h"), x),
      skill_name = mouFujian.name,
      prompt = "$ViewCardsFrom:" .. to.id,
    })
  end,
})

return mouFujian
