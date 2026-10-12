local mobileDaoshu = fk.CreateSkill {
  name = "mobile__daoshu",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") or Fk:currentRoom():isGameMode("2v2_mode") then
      return "mobile__daoshu_1v2"
    else
      return "mobile__daoshu_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["mobile__daoshu"] = "盗书",
  [":mobile__daoshu"] = "出牌阶段限一次，你可以选择一名手牌数不少于2的其他角色，该角色从随机三个牌名中选择一个，" ..
  "并将一张牌名不同的手牌伪装成此牌名的牌，然后你观看其伪装后的手牌，并猜测其中伪装过的牌（若为2v2或斗地主，" ..
  "则改为选择一名手牌数不少于2的敌方角色，且你与友方角色同时猜测）。猜中的角色对该角色各造成1点伤害，" ..
  "猜错的角色分别随机弃置两张手牌，若手牌不足则改为失去1点体力。",
  [":mobile__daoshu_1v2"] = "出牌阶段限一次，你可以选择一名手牌数不少于2的敌方角色，该角色从随机三个牌名中选择一个，" ..
  "并将一张牌名不同的手牌伪装成此牌名的牌，然后你观看其伪装后的手牌，并与友方角色同时猜测其中伪装过的牌。" ..
  "猜中的角色对该角色各造成1点伤害，猜错的角色分别随机弃置两张手牌，若手牌不足则改为失去1点体力。",
  [":mobile__daoshu_role_mode"] = "出牌阶段限一次，你可以选择一名手牌数不少于2的其他角色，该角色从随机三个牌名中选择一个，" ..
  "并将一张牌名不同的手牌伪装成此牌名的牌，然后你观看其伪装后的手牌，并猜测其中伪装过的牌。" ..
  "猜中的角色对该角色各造成1点伤害，猜错的角色分别随机弃置两张手牌，若手牌不足则改为失去1点体力。",

  ["#mobile__daoshu"] = "盗书：你可与队友查看1名敌人的手牌，并找出其伪装牌名的牌",
  ["#mobile__daoshu-choose"] = "盗书：请选择左侧的牌名并选择一张手牌，将此牌伪装成此牌名",
  ["#mobile__daoshu-guess"] = "猜测其中伪装牌名的牌",

  ["$mobile__daoshu1"] = "嗨！不过区区信件，何妨故友一观？",
  ["$mobile__daoshu2"] = "幸吾有备而来，不然为汝所戏矣。",
  ["$mobile__daoshu3"] = "亏我一世英名，竟上了周瑜的大当！",
}

mobileDaoshu:addEffect("active", {
  prompt = "#mobile__daoshu",
  mute = true,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(mobileDaoshu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = to_select
    if #selected >= 1 or target:getHandcardNum() < 2 then
      return false
    end

    if Fk:currentRoom():isGameMode("2v2_mode") or Fk:currentRoom():isGameMode("1v2_mode") then
      return target.role ~= player.role
    end

    return to_select ~= player
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = mobileDaoshu.name
    local player = effect.from
    player:broadcastSkillInvoke(skillName, 1)
    room:notifySkillInvoked(player, skillName, "offensive")
    local target = effect.tos[1]

    local cardNames = Fk:getAllCardNames("btde")
    local randomNames = room:tableRandomPick(cardNames, 3)
    room:setPlayerMark(target, "mobile__daoshu_names", randomNames)
    local _, dat = room:askToUseActiveSkill(
      target,
      {
        skill_name = "mobile__daoshu_choose",
        prompt = "#mobile__daoshu-choose",
        cancelable = false,
      }
    )
    room:setPlayerMark(target, "mobile__daoshu_names", 0)

    local cardChosen = (dat and #dat.cards > 0) and dat.cards[1] or room:tableRandomPick(target:getCardIds("h"))
    local newName = (dat and dat.interaction) and dat.interaction or room:tableRandomPick(
      table.filter(randomNames,
      function(name) return name ~= Fk:getCardById(cardChosen).name end)
    )
    local fake_index = 1
    local newHandIds = table.map(target:getCardIds("h"), function(id, index)
      if id == cardChosen then
        local card = Fk:getCardById(id)
        fake_index = index
        return {
          extension = card.package.extensionName,
          number = card.number,
          suit = card:getSuitString(),
          color = card:getColorString(),
        }
      end

      return id
    end)

    local friends = { player }
    if room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode") then
      friends = player:getFriends()
    end

    local req = Request:new(friends, "CustomDialog")
    req.focus_text = skillName
    for _, p in ipairs(friends) do
      req:setData(p, {
        component = {
          url = "packages/mobile/qml/DaoShuBox.qml",
          prop = {
            cards = newHandIds,
            fake_index = fake_index - 1,
            fake_name = newName,
          },
        }
      })
      req:setDefaultReply(p, room:tableRandomPick(target:getCardIds("h")))
    end

    req:ask()

    room:sortByAction(friends)
    for _, p in ipairs(friends) do
      if p:isAlive() then
        local cardGuessed = req:getResult(p)

        if cardGuessed == 0 then
          if p == player then
            player:broadcastSkillInvoke(skillName, 2)
          end
          room:damage{
            from = p,
            to = target,
            damage = 1,
            skillName = skillName,
          }
        else
          if p == player then
            player:broadcastSkillInvoke(skillName, 3)
          end
          if# p:getCardIds("h") > 1 then
            local canDiscard = table.filter(p:getCardIds("h"), function(id) return not p:prohibitDiscard(Fk:getCardById(id)) end)
            if #canDiscard then
              room:throwCard(room:tableRandomPick(canDiscard, 2), skillName, p, p)
            end
          else
            room:loseHp(p, 1, skillName)
          end
        end
      end
    end
  end,
})

return mobileDaoshu
