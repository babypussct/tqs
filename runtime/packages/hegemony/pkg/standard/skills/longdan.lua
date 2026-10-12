
local H = require "packages.hegemony.util"

local longdan = fk.CreateSkill{
  name = "hs__longdan",
  dynamic_desc = function(self, player)
    if H.hasHegLordSkill(Fk:currentRoom(), player, "shouyue") then
      return "hs__longdan_shouyue"
    else
      return "hs__longdan"
    end
  end,
}

Fk:loadTranslationTable{
  ["hs__longdan"] = "龙胆",
  [":hs__longdan"] = "你可以将【闪】当【杀】使用或打出，当此【杀】被一名角色使用的【闪】抵消后，你可以对另一名角色造成1点伤害。"..
  "你可以将【杀】当【闪】使用或打出，当一名角色使用的【杀】被此【闪】抵消后，你可以令另一名其他角色回复1点体力。",

  ["hs__longdan_shouyue"] = "龙胆",
  [":hs__longdan_shouyue"] = "你可以将【闪】当【杀】使用或打出，当此【杀】被一名角色使用的【闪】抵消后，你可以对另一名角色造成1点伤害。"..
  "你可以将【杀】当【闪】使用或打出，当一名角色使用的【杀】被此【闪】抵消后，你可以令另一名其他角色回复1点体力。"..
  "当你使用/打出因〖龙胆〗转化的普【杀】或【闪】时，你摸一张牌。",

  ["#longdan_slash-ask"] = "龙胆：你可以对 %dest 以外的一名角色造成1点伤害",
  ["#longdan_jink-ask"] = "龙胆：你可以令 %dest 以外的一名角色回复1点体力",

  ["$hs__longdan1"] = "能进能退，乃真正法器！",
  ["$hs__longdan2"] = "吾乃常山赵子龙也！",
}

longdan:addEffect('viewas', {
  pattern = "slash,jink",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.trueName == "jink" then
      c = Fk:cloneCard("slash")
    else
      return false
    end
    c:addSubcard(to_select)
    return (Fk.currentResponsePattern == nil and player:canUse(c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.trueName == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillName = longdan.name
    c:addSubcard(cards[1])
    return c
  end,
})
longdan:addEffect(fk.CardEffectCancelledOut, {
  is_delay_effect = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if data.card.trueName ~= "slash" then return false end
    if target == player then -- 龙胆杀
      return table.contains(data.card.skillNames, "hs__longdan")
    elseif data.to == player then -- 龙胆闪
      for _, card in ipairs(data.cardsResponded) do
        if card.name == "jink" and table.contains(card.skillNames, "hs__longdan") then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos
    if target == player then
      local targets = room:getOtherPlayers(data.to)
      if #targets == 0 then return false end
      tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#longdan_slash-ask::" .. data.to.id,
        skill_name = longdan.name,
        cancelable = true,
      })
    else
      local targets = table.filter(room:getOtherPlayers(target), function(p) return
        p ~= player and p:isWounded()
      end)
      if #targets == 0 then return false end
      tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#longdan_jink-ask::" .. target.id,
        skill_name = longdan.name,
        cancelable = true,
      })
    end
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if target == player then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = longdan.name,
      }
    else
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = longdan.name,
      })
    end
  end,
})

---@type TrigSkelSpec<UseCardFunc|RespondCardFunc>
local longdan_draw_spec = {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player == target and
      table.contains(data.card.skillNames, longdan.name) and H.hasHegLordSkill(player.room, player, "shouyue")
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, longdan.name)
  end,
}
longdan:addEffect(fk.CardUsing, longdan_draw_spec)
longdan:addEffect(fk.CardResponding, longdan_draw_spec)

return longdan
