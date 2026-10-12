local sanchen = fk.CreateSkill{
  name = "heg__sanchen",
}

Fk:loadTranslationTable{
  ["heg__sanchen"] = "三陈",
  [":heg__sanchen"] = "出牌阶段，对每名角色限一次，若你的武将牌均明置，" ..
  "你可令一名角色摸三张牌然后弃置三张牌，若其因此弃置了类别相同的牌，你暗置此武将牌。",

  ["@@heg__sanchen_used-phase"] = "已三陈",
  ["#heg__sanchen-discard"] = "三陈：弃置三张牌，若其中有类别相同的牌，%src暗置",

  ["$heg__sanchen1"] = "陈书弼国，当一而再、再而三。",
  ["$heg__sanchen2"] = "勘除弼事，三陈而就。",
}

local H = require "packages.hegemony.util"

sanchen:addEffect("active", {
  anim_type = "support",
  can_use = function (self, player)
    return H.allGeneralsRevealed(player)
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function (self, player, to_select, selected)
    return to_select:getMark("@@heg__sanchen_used-phase") == 0 and #selected == 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    room:setPlayerMark(to, "@@heg__sanchen_used-phase", 1)
    to:drawCards(3, sanchen.name)
    if to:isAlive() then
      local cards = room:askToDiscard(to, {
        min_num = 3,
        max_num = 3,
        skill_name = sanchen.name,
        prompt = "#heg__sanchen-discard:" .. player.id,
        cancelable = false,
      })
      if #cards > 0 then
        local types = {}
        for _, id in ipairs(cards) do
          local card = Fk:getCardById(id)
          if not table.insertIfNeed(types, card.type) then
            H.hideBySkillName(player, sanchen.name)
            break
          end
        end
      end
    end
  end
})

return sanchen
