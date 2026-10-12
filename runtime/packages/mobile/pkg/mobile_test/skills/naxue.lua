local naxue = fk.CreateSkill {
  name = "naxue",
}

Fk:loadTranslationTable{
  ["naxue"] = "纳学",
  [":naxue"] = "你可以跳过出牌阶段，若如此做，你可以弃置任意张牌，摸等量的牌，然后交给至多两名其他角色各一张牌。",

  ["#naxue-discard"] = "纳学：你可以弃置任意张牌，摸等量的牌",
  ["#naxue-give"] = "纳学：你可以交给至多两名其他角色各一张牌",

  ["$naxue1"] = "诸位正值年少，勿负此读书良时。",
  ["$naxue2"] = "老夫积书万卷，可供诸生阅览。",
}

naxue:addEffect(fk.EventPhaseChanging, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(naxue.name) and data.phase == Player.Play and
      not data.skipped
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.skipped = true
    if not player:isNude() then
      local cards = room:askToDiscard(player, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        skill_name = naxue.name,
        prompt = "#naxue-discard",
        cancelable = true,
      })
      if player.dead then return end
      if #cards > 0 then
        player:drawCards(#cards, naxue.name)
        if player.dead then return end
      end
    end
    if not player:isNude() and #room:getOtherPlayers(player, false) > 0 then
      room:askToYiji(player, {
        cards = player:getCardIds("he"),
        targets = room:getOtherPlayers(player, false),
        skill_name = naxue.name,
        min_num = 0,
        max_num = 2,
        prompt = "#naxue-give",
        single_max = 1,
      })
    end
  end,
})

return naxue
