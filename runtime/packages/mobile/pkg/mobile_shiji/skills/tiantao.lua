local tiantao = fk.CreateSkill{
  name = "tiantao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tiantao"] = "天涛",
  [":tiantao"] = "锁定技，结束阶段，你选择一个区域并弃置其中所有牌，然后依次弃置任意名其他角色相同区域各一张牌，"..
    "因此弃置牌且未弃置【杀】的角色失去1点体力。",

  ["#tiantao-choice"] = "天涛：选择1个区域，弃置其中的所有牌",
  ["#tiantao-choose"] = "天涛：选择任意名其他角色，弃置这些角色的%arg各1张牌",

  ["$tiantao1"] = "以此天穹之水，涤瑕荡秽！",
  ["$tiantao2"] = "心怀浊恶之徒，岂能承神雨之清？",
}

tiantao:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tiantao.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local skillName = tiantao.name
    local room = player.room
    local choice = room:askToChoice(
      player,
      {
        choices = { "$Hand", "$Equip", "$Judge" },
        skill_name = skillName,
        prompt = "#tiantao-choice",
      }
    )
    local areaMapper = {
      ["$Hand"] = "h",
      ["$Equip"] = "e",
      ["$Judge"] = "j",
    }
    local area = areaMapper[choice]
    local card
    local loseHp = { player }
    local cards = table.filter(player:getCardIds(area), function(id)
      card = Fk:getCardById(id)
      if not player:prohibitDiscard(card) then
        if #loseHp > 0 and card.trueName == "slash" then
          loseHp = {}
        end
        return true
      end
    end)
    if #cards > 0 then
      room:throwCard(cards, skillName, player, player)
      if player.dead then return end
    else
      loseHp = {}
    end

    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and #p:getCardIds(area) > 0
    end)
    if #targets > 0 then
      targets = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 998,
        targets = targets,
        skill_name = skillName,
        prompt = "#tiantao-choose:::" .. choice,
        cancelable = false,
      })
      --room:sortByAction(targets)
      for _, p in ipairs(targets) do
        if not (player.dead or p.dead or #p:getCardIds(area) == 0) then
          local id = room:askToChooseCard(player, {
            target = p,
            skill_name = skillName,
            flag = area,
          })
          if Fk:getCardById(id).trueName ~= "slash" then
            table.insert(loseHp, p)
          end
          room:throwCard(id, skillName, p, player)
        end
      end
    end

    for _, p in ipairs(loseHp) do
      if not p.dead then
        room:loseHp(p, 1, skillName, player)
      end
    end
  end,
})

return tiantao
