
local tanfeng = fk.CreateSkill{
  name = "tanfeng",
}

Fk:loadTranslationTable{
  ["tanfeng"] = "探锋",
  [":tanfeng"] = "准备阶段，你可以选择任意项：1.弃置一名角色至多两张牌，然后若其手牌数不大于你，你跳过摸牌阶段；2.对一名角色造成1点火焰伤害，"..
  "然后若其体力值不大于你，你跳过出牌阶段。",

  ["tanfeng_discard"] = "弃置一名角色牌",
  ["tanfeng_damage"] = "造成火属性伤害",

  ["#tanfeng1-choose"] = "探锋：弃置一名角色至多两张牌，若其手牌数不大于你则跳过摸牌阶段",
  ["#tanfeng2-choose"] = "探锋：对一名角色造成伤害，若其体力值不大于你则跳过出牌阶段",

  ["$tanfeng1"] = "探敌薄防之地，夺敌不备之间。",
  ["$tanfeng2"] = "探锋之锐，以待进取之机。",
}

tanfeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tanfeng.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local allChoices = { "tanfeng_discard", "tanfeng_damage" }
    local choices = table.simpleClone(allChoices)
    local targets = table.filter(room.alive_players, function(p)
      return not p:isNude()
    end)
    if table.contains(targets, player) and
      not table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end

    if #targets == 0 then
      table.remove(choices, 1)
    end

    local choices = room:askToChoices(
      player,
      {
        min_num = 1,
        max_num = 2,
        choices = choices,
        skill_name = tanfeng.name,
        all_choices = allChoices,
      }
    )

    if #choices > 0 then
      event:setCostData(self, { choices = choices })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choices

    if table.contains(choices, "tanfeng_discard") then
      local targets = table.filter(room.alive_players, function(p)
        return not p:isNude()
      end)
      if table.contains(targets, player) and
        not table.find(player:getCardIds("he"), function (id)
          return not player:prohibitDiscard(id)
        end) then
        table.removeOne(targets, player)
      end
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#tanfeng1-choose",
          skill_name = tanfeng.name,
          cancelable = false,
        })[1]
        if to == player then
          room:askToDiscard(player, {
            min_num = 1,
            max_num = 2,
            include_equip = true,
            skill_name = tanfeng.name,
            cancelable = false,
          })
        else
          local cards = room:askToChooseCards(player, {
            target = to,
            min = 1,
            max = 2,
            flag = "he",
            skill_name = tanfeng.name,
          })
          room:throwCard(cards, tanfeng.name, to, player)
        end
        if to:getHandcardNum() <= player:getHandcardNum() then
          player:skip(Player.Draw)
        end
        if player.dead then return end
      end
    end

    if table.contains(choices, "tanfeng_damage") then
      local to = room:askToChoosePlayers(player, {
        targets = room:getAlivePlayers(false),
        min_num = 1,
        max_num = 1,
        prompt = "#tanfeng2-choose",
        skill_name = tanfeng.name,
        cancelable = false,
      })[1]

      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = tanfeng.name,
      }
      if to.hp <= player.hp then
        player:skip(Player.Play)
      end
    end
  end,
})

return tanfeng
