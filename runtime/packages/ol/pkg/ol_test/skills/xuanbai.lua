
local xuanbai = fk.CreateSkill {
  name = "xuanbai",
  tags = { Skill.Compulsory },
  related_skills = { "ol__dangmo", "jihui", "xiaju" },
}

Fk:loadTranslationTable{
  ["xuanbai"] = "玄白",
  [":xuanbai"] = "锁定技，当<a href=':colorful_lotus'>【彩莲】</a>进入你的一个装备栏后，你切换为不同的形态：<br>"..
  "武器栏-〖荡魔〗；防具栏-〖济惠〗；宝物栏-〖霞举〗。",

  ["$xuanbai1"] = "",
  ["$xuanbai2"] = "",
}

xuanbai:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xuanbai.name) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerEquip then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "colorful_lotus" then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    for _, card in ipairs(player:getEquipCards()) do
      if card.name == "colorful_lotus" then
        if card.sub_type == Card.SubtypeWeapon then
          table.insert(skills, "ol__dangmo")
        elseif card.sub_type == Card.SubtypeArmor then
          table.insert(skills, "jihui")
        elseif card.sub_type == Card.SubtypeTreasure then
          table.insert(skills, "xiaju")
        end
      end
    end
    for _, s in ipairs(xuanbai.related_skills) do
      if table.contains(skills, s) then
        if not player:hasSkill(s, true) then
          room:handleAddLoseSkills(player, s)
        end
      else
        if player:hasSkill(s, true) then
          room:handleAddLoseSkills(player, "-"..s)
        end
      end
    end
  end,
})

return xuanbai
