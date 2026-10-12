local feijing = fk.CreateSkill {
  name = "feijing",
}

Fk:loadTranslationTable{
  ["feijing"] = "飞径",
  [":feijing"] = "你可以将一张伤害类锦囊牌当【杀】使用或打出；每回合限两次，当你使用【杀】指定唯一目标时，"..
  "你可以令你与其一条<a href='#PathDesc'>路径</a>之间的所有角色同时展示并依次弃置一张手牌，然后你可以选择一种颜色，弃置此颜色牌的角色成为此【杀】的额外目标。",

  ["#feijing"] = "飞径：你可以将伤害类锦囊牌当【杀】使用或打出",
  ["#feijing-choosePath"] = "飞径：请选择你与 %dest 之间的一条路径",
  ["#feijing-display"] = "飞径：请选择一张手牌展示并弃置",
  ["#feijing-choose"] = "飞径：你可选择一种颜色，弃置该颜色牌的角色成为【杀】的额外目标",

  ["$feijing1"] = "吔，可知我军中飞燕的厉害！",
  ["$feijing2"] = "怪汝时运不济，栽在我的手里。",
  ["$feijing3"] = "家家皆掠，鸡犬不留！",
  ["$feijing4"] = "我要看到赤地千里，荒无人烟。",
}

feijing:addEffect("viewas", {
  audio_index = { 1, 2 },
  pattern = "slash",
  prompt = "#feijing",
  handly_pile = true,
  card_filter = function(self, player, to_select)
    local card = Fk:getCardById(to_select)
    return (card.type == Card.TypeTrick and card.is_damage_card) or card.name == "lightning"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end

    local slash = Fk:cloneCard("slash")
    slash:addSubcard(cards[1])
    slash.skillName = feijing.name
    return slash
  end,
})

feijing:addEffect(fk.TargetSpecifying, {
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.firstTarget and
      data.card.trueName == "slash" and
      player:hasSkill(feijing.name) and
      data:isOnlyTarget(data.to) and
      data.to ~= player and
      data.to:isAlive() and
      not data.to:isRemoved() and
      player:usedEffectTimes(self.name) < 2 and
      (
        (player:getNextAlive() ~= data.to and player:getNextAlive() ~= player) or
        (data.to:getNextAlive() ~= player and data.to:getNextAlive() ~= data.to)
      )
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(
      player,
      {
        skill_name = "#choose_path",
        prompt = "#feijing-choosePath::" .. data.to.id,
        extra_data = { pathTarget = data.to.id }
      }
    )

    if success and dat and dat.interaction then
      event:setCostData(self, { choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if not data.to:isAlive() or data.to:isRemoved() then
      return false
    end

    local room = player.room
    ---@type string
    local skillName = feijing.name
    local choice = event:getCostData(self).choice
    local targets = {}
    if choice == "clockwise" then
      local curPlayer = data.to
      for _ = 1, #room.alive_players do
        curPlayer = curPlayer:getNextAlive()
        if curPlayer == player then
          break
        end
        room:doIndicate(player, { curPlayer })
        table.insert(targets, curPlayer)
      end
    elseif choice == "anticlockwise" then
      local curPlayer = player
      for _ = 1, #room.alive_players do
        curPlayer = curPlayer:getNextAlive()
        if curPlayer == data.to then
          break
        end
        room:doIndicate(player, { curPlayer })
        table.insert(targets, curPlayer)
      end
    end

    targets = table.filter(targets, function(p) return not p:isKongcheng() end)
    if #targets == 0 then
      return false
    end

    room:sortByAction(targets)
    local results = room:askToJointCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        players = targets,
        prompt = "#feijing-display",
        skill_name = skillName,
        cancelable = false,
      }
    )

    local colorsDiscard = {}
    for _, p in ipairs(targets) do
      local id = results[p][1]
      if p:isAlive() and table.contains(p:getCardIds("h"), id) then
        p:showCards(id)
      end
    end

    for _, p in ipairs(targets) do
      local id = results[p][1]
      if p:isAlive() and not p:prohibitDiscard(id) and table.contains(p:getCardIds("h"), id) then
        colorsDiscard[p] = Fk:getCardById(id):getColorString()
        room:throwCard(id, skillName, p, p)
      end
    end

    if next(colorsDiscard) == nil then
      return false
    end

    local colorChosen = room:askToChoice(
      player,
      {
        choices = { "black", "red", "Cancel" },
        skill_name = skillName,
        prompt = "#feijing-choose",
      }
    )

    if colorChosen == "Cancel" then
      return false
    end

    for p, color in pairs(colorsDiscard) do
      if colorChosen == color and not player:isProhibited(p, data.card) then
        room:doIndicate(player, { p })
        data:addTarget(p)
        data.extra_data = data.extra_data or {}
        data.extra_data.feijingExtra = data.extra_data.feijingExtra or {}
        data.extra_data.feijingExtra[p] = results[p]
      end
    end
  end,
})

feijing:addAI(nil, "vs_skill")

return feijing
