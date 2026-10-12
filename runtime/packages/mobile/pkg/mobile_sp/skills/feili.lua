local feili = fk.CreateSkill {
  name = "feili",
}

Fk:loadTranslationTable{
  ["feili"] = "诽离",
  [":feili"] = "当你受到伤害时，若你拥有〖谮构〗，你可以弃置两张牌防止此伤害；"..
  "若伤害来源拥有“诬”标记，你可以改为移除此标记防止此伤害，然后你摸两张牌且本局游戏不能对其发动〖谮构〗。",

  ["#feili-invoke"] = "诽离：是否弃置“诬”标记或两张牌，防止你受到的伤害",
  ["#feili-discard"] = "诽离：弃置两张牌，防止此伤害",
  ["feili_removemark"] = "移除%dest的“诬”标记",
  ["feili_discard"] = "弃置两张牌",

  ["$feili1"] = "怪我未下狠手，让你饶幸生还。",
  ["$feili2"] = "夏侯楙，事已至此，何必再惺惺作态。",
}

local U = require "packages.utility.utility"

feili:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(feili.name) and player:hasSkill("mobile__zengou", true) and
      (#player:getCardIds("he") >= math.max(1, player:getMark("@mobile__zengou-round")) or
      (data.from and data.from:getMark("@[private]mobile__zengou_wu") ~= 0))
  end,
  on_cost = function(self, event, target, player, data)
    local x = math.max(1, player:getMark("@mobile__zengou-round"))
    if data.from and data.from:getMark("@[private]mobile__zengou_wu") ~= 0 then
      local cards, choice = U.askForCardByMultiPatterns(
        player,
        {
          { ".", 2, 2, "feili_discard" },
          { ".", 0, 0, "feili_removemark::" .. data.from.id }
        },
        feili.name,
        true,
        "#feili-invoke",
        {
          discard_skill = true
        }
      )
      if choice == "" then return false end
      if #cards > 0 then
        event:setCostData(self, { cards = cards })
        return true
      else
        event:setCostData(self, { tos = { data.from }, cards = cards })
        return true
      end
    else
      local cards = player.room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = feili.name,
        cancelable = true,
        prompt = "#feili-discard",
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, { cards = cards })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local cards = event:getCostData(self).cards
    if #cards > 0 then
      room:throwCard(cards, feili.name, player, player)
    else
      room:setPlayerMark(data.from, "@[private]mobile__zengou_wu", 0)
      room:drawCards(player, 2, feili.name)
      if player:hasSkill("mobile__zengou", true) then
        room:addTableMark(player, "mobile__zengou_prohibit", data.from.id)
      end
    end
  end,
})

return feili
