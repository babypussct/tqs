local zhengjun = fk.CreateSkill {
  name = "os__zhengjun",
}

Fk:loadTranslationTable{
  ["os__zhengjun"] = "整军",
  [":os__zhengjun"] = "当你不因使用或打出失去手牌后，你可以选择一项："..
  "1.从牌堆或弃牌堆中获得一张【火攻】；2.将手牌补至体力上限。"..
  "当你一轮内因此技能获得的牌数不小于2时，此技能本轮失效。",

  ["os__zhengjun_fire_attack"] = "获得一张【火攻】",
  ["os__zhengjun_draw"] = "将手牌补至体力上限",

  ["$os__zhengjun1"] = "宽仁爱士，何愁无威武之师。",
  ["$os__zhengjun2"] = "首战告捷，众士皆有封赏。",
  ["$os__zhengjun3"] = "无军纪之束，果然难成雄兵。",
}

zhengjun:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhengjun.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResponse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = { "os__zhengjun_fire_attack" }
    if player:getHandcardNum() < player.maxHp then
      table.insert(choices, "os__zhengjun_draw")
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhengjun.name,
      all_choices = { "os__zhengjun_fire_attack", "os__zhengjun_draw", "Cancel" },
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local n = 1
    if choice == "os__zhengjun_fire_attack" then
      local card = room:getCardsFromPileByRule("fire_attack", 1, "allPiles")
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, zhengjun.name, nil, false, player)
      end
    else
      n = #player:drawCards(player.maxHp - player:getHandcardNum(), zhengjun.name)
    end
    room:addPlayerMark(player, "os__zhengjun-round", n)
    if player:getMark("os__zhengjun-round") > 1 then
      room:invalidateSkill(player, zhengjun.name, "-round")
    end
  end,
})

return zhengjun
