local chenglue = fk.CreateSkill {
  name = "ol_heg__chenglue",
}

Fk:loadTranslationTable {
  ["ol_heg__chenglue"] = "成略",
  [":ol_heg__chenglue"] = "与你势力相同的角色出牌阶段开始时，你可以将一张牌置于牌堆顶，令其选择一项："..
  "1.弃置两张牌，本回合其使用这些花色的牌无距离和次数限制；"..
  "2.其可与你<a href='heg__yiwei'>易位</a>，然后控制此武将牌的角色摸一张牌。",

  ["#ol_heg__chenglue"] = "成略：将一张牌置于牌堆顶，令 %src 选择一项效果",
  ["ol_heg__chenglue-yiwei"] = "与 %src 易位，然后控制许攸的角色摸一张牌",
  ["ol_heg__chenglue-discard"] = "弃置两张牌，本回合使用这些花色的牌无距离和次数限制",
  ["#ol_heg__chenglue-discard"] = "成略：弃置两张牌，本回合使用这些花色的牌无距离和次数限制",
  ["@ol_heg__chenglue-turn"] = "成略",
}

local H = require "packages.hegemony.util"

chenglue:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenglue.name) and H.compareKingdomWith(target, player) and not player:isNude()
    and target.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player,{
      min_num = 1,
      max_num = 1,
      pattern = ".",
      skill_name = chenglue.name,
      skip = true,
      prompt = "#ol_heg__chenglue:" .. target.id,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards, tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCards({
      ids = event:getCostData(self).cards,
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = chenglue.name,
      drawPilePosition = 1,
      moveVisible = true,
    })
    if player.dead or target.dead then return end
    local choices = { "ol_heg__chenglue-yiwei:"..player.id }
    if #target:getCardIds("he") > 1 then
      table.insert(choices, "ol_heg__chenglue-discard")
    end
    local choice = room:askToChoice(target,{
      choices = choices,
      all_choices = { "ol_heg__chenglue-yiwei:"..player.id, "ol_heg__chenglue-discard" },
      skill_name = chenglue.name,
      cancelable = false,
    })
    if choice:startsWith("ol_heg__chenglue-yiwei") then
      H.swapDeputy(room, player, target)
      if target ~= player then
        if H.isControllingGeneral(player, "olheg__xuyou") then
          player:drawCards(1, chenglue.name)
        elseif H.isControllingGeneral(target, "olheg__xuyou") then
          target:drawCards(1, chenglue.name)
        end
        else
          player:drawCards(1, chenglue.name)
        end
    else
      local toDiscard = room:askToDiscard(target,{
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = chenglue.name,
        cancelable = false,
        prompt = "#ol_heg__chenglue-discard",
        skip = true,
      })
      if #toDiscard == 0 then return end
        for _, id in ipairs(toDiscard) do
          local suit = Fk:getCardById(id):getSuitString(true)
          if suit ~= "log_nosuit" then
            room:addTableMarkIfNeed(target, "@ol_heg__chenglue-turn", suit)
          end
        end
      room:throwCard(toDiscard, chenglue.name, target, target)
    end
  end,
})

chenglue:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    local mark = player:getTableMark("@ol_heg__chenglue-turn")
    if #mark > 0 then
      return card and card:matchVSPattern(".|.|"..table.concat(table.map(mark, function(suit) return string.sub(suit, 5) end), ","))
    end
  end,
  bypass_distances = function(self, player, skill, card)
    local mark = player:getTableMark("@ol_heg__chenglue-turn")
    if #mark > 0 then
      return card and card:matchVSPattern(".|.|" ..table.concat(table.map(mark, function(suit) return string.sub(suit, 5) end), ","))
    end
  end,
})

return chenglue
