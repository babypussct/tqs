
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

-- Prompt 4: choose the legal Slash/Jink conversion instead of accepting the
-- first raw card.  The response branch only sees the requested pattern; the
-- play branch evaluates the converted Slash against public faction state.
longdan:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local skill = Fk.skills[self.skill_name]
    local requested = type(ai.data) == "table" and ai.data[2] or ""
    local is_response = ai.command == "AskForResponseCard"
    local extra_data = type(ai.data) == "table" and
      ((type(ai.data[5]) == "table" and ai.data[5]) or
       (type(ai.data[4]) == "table" and ai.data[4])) or {}
    local best, best_value = nil, -100000
    local cards = ai:getEnabledCards()

    for _, id in ipairs(cards) do
      local card = skill:viewAs(ai.player, { id })
      if card then
        if is_response then
          local pattern_ok = type(requested) == "string" and
            Exppattern:Parse(requested):match(card)
          if pattern_ok then
            local value = 1 - (ai:getCardValue(id, "keep_value") or 0) * 0.01
            if value > best_value then
              best, best_value = { { id }, {} }, value
            end
          end
        elseif card.trueName == "slash" then
          ai:selectSkill(self.skill_name, true)
          ai:selectCard(id, true)
          -- getDefaultTarget() is intentionally random.  Exhaust every
          -- server-legal public target here so the native probe and real AI
          -- do not turn the same request into a different reply merely from
          -- Lua RNG state, and so an ally is never selected when an enemy is
          -- available.  The target list is server-derived; no hidden hand or
          -- general information is consulted.
          for _, target in ipairs(card:getAvailableTargets(ai.player, extra_data)) do
            local targets = { target }
            local value = ai:getBenefitOfEvents(function(logic)
              logic:useCard{ from = ai.player, tos = targets, card = card }
            end)
            value = value - (ai:getCardValue(id, "keep_value") or 0) * 12
            if value > best_value then
              best, best_value = { { id }, targets }, value
            end
          end
          ai:unSelectAll()
        end
      end
    end

    if best and (is_response or best_value > 0) then return best, best_value end
  end,
})

-- The cancellation follow-up is a separate choose-players request.  Damage
-- is reserved for a public/probable enemy; recovery is reserved for a
-- confirmed or sufficiently evidenced ally, using no hidden hand/general
-- information.
longdan:addAI(Fk.Ltk.AI.newChoosePlayersStrategy {
  choose_players = function(self, ai)
    local prompt = type(ai.data) == "table" and ai.data[2] or ""
    local is_recover = type(prompt) == "string" and prompt:startsWith("#longdan_jink-ask")
    local best, best_value = nil, -100000
    for _, target in ipairs(ai:getEnabledTargets()) do
      local relation = ai:getFactionRelation(target)
      local allowed = is_recover
        and (relation.state == "friend" or
          (relation.state == "unknown" and relation.confidence >= 0.65 and relation.attitude > 0.25))
        or (relation.state == "enemy" or
          (relation.state == "unknown" and relation.confidence >= 0.65 and relation.attitude < -0.25))
      if allowed then
        local value = ai:getBenefitOfEvents(function(logic)
          if is_recover then
            logic:recover{ who = target, num = 1, recoverBy = ai.player, skillName = self.skill_name }
          else
            logic:damage{ from = ai.player, to = target, damage = 1, skillName = self.skill_name }
          end
        end)
        if value > best_value then best, best_value = target, value end
      end
    end

    local cancelable = type(ai.data) == "table" and ai.data[3] == true
    if best and (best_value > 0 or not cancelable) then return { best }, best_value end
    if cancelable then return {}, 0 end
  end,
})

return longdan
