-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("ol_derived", Package.CardPack)
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_derived/skills")

Fk:loadTranslationTable{
  ["ol_derived"] = "OL衍生牌",
}

local grain_cart = fk.CreateCard{
  name = "&grain_cart",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#grain_cart_skill",
}
extension:addCardSpec("grain_cart", Card.Heart, 5)
Fk:loadTranslationTable{
  ["grain_cart"] = "四乘粮舆",
  [":grain_cart"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：一名角色的回合结束时，若你的手牌数小于体力值，你可以摸两张牌，然后弃置此牌。",
}

local caltrop_cart = fk.CreateCard{
  name = "&caltrop_cart",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#caltrop_cart_skill",
}
extension:addCardSpec("caltrop_cart", Card.Club, 5)
Fk:loadTranslationTable{
  ["caltrop_cart"] = "铁蒺玄舆",
  [":caltrop_cart"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：其他角色的回合结束时，若其本回合未造成过伤害，你可以令其弃置两张牌，然后弃置此牌。",
}

local wheel_cart = fk.CreateCard{
  name = "&wheel_cart",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#wheel_cart_skill",
}
extension:addCardSpec("wheel_cart", Card.Spade, 5)
Fk:loadTranslationTable{
  ["wheel_cart"] = "飞轮战舆",
  [":wheel_cart"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：其他角色的回合结束时，若其本回合使用过非基本牌，你可以令其交给你一张牌，然后弃置此牌。",
}

local jade_comb = fk.CreateCard{
  name = "&jade_comb",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#jade_comb_skill",
}
extension:addCardSpec("jade_comb", Card.Spade, 12)
Fk:loadTranslationTable{
  ["jade_comb"] = "琼梳",
  [":jade_comb"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：当你受到伤害时，你可以弃置X张牌（X为伤害值），防止此伤害。",
}

local rhino_comb = fk.CreateCard{
  name = "&rhino_comb",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#rhino_comb_skill",
}
extension:addCardSpec("rhino_comb", Card.Club, 12)
Fk:loadTranslationTable{
  ["rhino_comb"] = "犀梳",
  [":rhino_comb"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：判定阶段开始前，你可选择：1.跳过此阶段；2.跳过此回合的弃牌阶段。",
}

local golden_comb = fk.CreateCard{
  name = "&golden_comb",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#golden_comb_skill",
}
extension:addCardSpec("golden_comb", Card.Heart, 12)
Fk:loadTranslationTable{
  ["golden_comb"] = "金梳",
  [":golden_comb"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，出牌阶段结束时，你将手牌补至X张（X为你的手牌上限且至多为5）。",
}

local sizhao_sword = fk.CreateCard{
  name = "&sizhao_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#sizhao_sword_skill",
}
extension:addCardSpec("sizhao_sword", Card.Diamond, 6)
Fk:loadTranslationTable{
  ["sizhao_sword"] = "思召剑",
  [":sizhao_sword"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：锁定技，当你使用【杀】指定一名角色为目标后，该角色不能使用点数小于此【杀】的【闪】以抵消此【杀】。",
}

local armillary_sphere = fk.CreateCard{
  name = "&armillary_sphere",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#armillary_sphere_skill",
}
extension:addCardSpec("armillary_sphere", Card.Diamond, 1)
extension:addCardSpec("armillary_sphere", Card.Diamond, 3)
extension:addCardSpec("armillary_sphere", Card.Diamond, 10)
extension:addCardSpec("armillary_sphere", Card.Diamond, 12)
Fk:loadTranslationTable{
  ["armillary_sphere"] = "浑天仪",
  [":armillary_sphere"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，你从装备区里失去此牌时，从牌堆中随机获得两张与此牌点数相同的锦囊牌。当你受到伤害时，销毁此牌并防止之。",
}

local catapult = fk.CreateCard{
  name = "&ol__catapult",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#ol__catapult_skill",
}
extension:addCardSpec("ol__catapult", Card.Diamond, 9)
Fk:loadTranslationTable{
  ["ol__catapult"] = "霹雳车",
  [":ol__catapult"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：9<br/>" ..
  "<b>武器技能</b>：当你对其他角色造成伤害后，你可以弃置其区域内的一张牌。此牌进入非装备区时，销毁之。",
}

local blood_blade = fk.CreateCard{
  name = "&blood_blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  dynamic_attack_range = function(self, player)
    if player and not player:hasSkill("shenyu", true) then
      return 0
    end
  end,
  equip_skill = "#blood_blade_skill",
  dynamic_equip_skills = function(self, player)
    if player and self:getMark("blood_blade") ~= 0 then
      return { Fk.skills[self:getMark("blood_blade")] }
    end
  end,
}
extension:addCardSpec("blood_blade", Card.Heart, 13)
Fk:loadTranslationTable{
  ["blood_blade"] = "赤血刃",
  [":blood_blade"] = "装备牌·武器<br/><b>攻击范围</b>：3（若你不拥有〖神御〗，改为0）<br/>"..
  "<b>武器技能</b>：锁定技，每回合首次你的【杀】对攻击范围内最远角色造成的伤害+1。此牌首次替换其他武器牌后，获得该武器牌的技能。",

  ["#blood_blade_skill"] = "赤血刃",
}

local colorful_lotus = fk.CreateCard{
  name = "&colorful_lotus",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 1,
  equip_skill = "#colorful_lotus_skill",
}
extension:addCardSpec("colorful_lotus")
Fk:loadTranslationTable{
  ["colorful_lotus"] = "彩莲",
  [":colorful_lotus"] = "装备牌·武器/防具/宝物<br/>"..
  "<b>攻击范围</b>：1<br/>" ..
  "<b>装备技能</b>：锁定技，你每轮首次造成的伤害与回复+1，且你与此牌花色相同的手牌不计入手牌上限。",
}

--神武
local ghost_dragon_blade = fk.CreateCard{
  name = "&ghost_dragon_blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#ghost_dragon_blade_skill",
}
extension:addCardSpec("ghost_dragon_blade", Card.Spade, 5)
Fk:loadTranslationTable{
  ["ghost_dragon_blade"] = "鬼龙斩月刀",
  [":ghost_dragon_blade"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：锁定技，你使用红色【杀】不能被响应。",

  ["#ghost_dragon_blade_skill"] = "鬼龙斩月刀",
}

local sage_cloak = fk.CreateCard{
  name = "&sage_cloak",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#sage_cloak_skill",
}
extension:addCardSpec("sage_cloak", Card.Spade, 9)
Fk:loadTranslationTable{
  ["sage_cloak"] = "国风玉袍",
  [":sage_cloak"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，你不能成为其他角色使用普通锦囊牌的目标。",
}

local fire_string = fk.CreateCard{
  name = "&fire_string",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#fire_string_skill",
}
extension:addCardSpec("fire_string", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["fire_string"] = "赤焰镇魂琴",
  [":fire_string"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/>"..
  "<b>武器技能</b>：锁定技，你使用的普【杀】改为火【杀】；你造成的伤害改为火焰伤害。",

  ["#fire_string_skill"] = "赤焰镇魂琴",
}

local mystical_diagram = fk.CreateCard{
  name = "&mystical_diagram",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#mystical_diagram_skill",
}
extension:addCardSpec("mystical_diagram", Card.Spade, 2)
Fk:loadTranslationTable{
  ["mystical_diagram"] = "奇门八卦",
  [":mystical_diagram"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，【杀】对你无效。",

  ["#mystical_diagram_skill"] = "奇门八卦",
}

local juechenjinge = fk.CreateCard{
  name = "&juechenjinge",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
  equip_skill = "#juechenjinge_skill",
}
extension:addCardSpec("juechenjinge", Card.Spade, 5)
Fk:loadTranslationTable{
  ["juechenjinge"] = "绝尘金戈",
  [":juechenjinge"] = "装备牌·坐骑<br/>"..
  "<b>坐骑技能</b>：锁定技，敌方角色计算与己方其他角色距离+1。",
}

local asura_halberd = fk.CreateCard{
  name = "&asura_halberd",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#asura_halberd_skill",
}
extension:addCardSpec("asura_halberd", Card.Diamond, 12)
Fk:loadTranslationTable{
  ["asura_halberd"] = "修罗炼狱戟",
  [":asura_halberd"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/>"..
  "<b>武器技能</b>：锁定技，你使用【杀】无目标数限制；当你使用【杀】对目标角色造成伤害时，此伤害+1，其受到伤害后回复1点体力。",

  ["#asura_halberd_skill"] = "修罗炼狱戟",
}

local blood_sword = fk.CreateCard{
  name = "&blood_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#blood_sword_skill",
}
extension:addCardSpec("blood_sword", Card.Spade, 6)
Fk:loadTranslationTable{
  ["blood_sword"] = "赤血青锋",
  [":blood_sword"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：锁定技，你使用【杀】指定目标后，此【杀】无视目标角色的防具且目标不能使用或打出手牌，直至此【杀】结算完毕。",
}

local illusory_coronet = fk.CreateCard{
  name = "&illusory_coronet",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#illusory_coronet_skill",
}
extension:addCardSpec("illusory_coronet", Card.Club, 4)
Fk:loadTranslationTable{
  ["illusory_coronet"] = "虚妄之冕",
  [":illusory_coronet"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，摸牌阶段，你额外摸两张牌；你的手牌上限-1。",

  ["#illusory_coronet_skill"] = "虚妄之冕",
}

local luanfeng_double_swords = fk.CreateCard{
  name = "&luanfeng_double_swords",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#luanfeng_double_swords_skill",
}
extension:addCardSpec("luanfeng_double_swords", Card.Spade, 2)
Fk:loadTranslationTable{
  ["luanfeng_double_swords"] = "鸾凤和鸣剑",
  [":luanfeng_double_swords"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：当你使用雷【杀】或火【杀】指定目标后，你可以令目标角色选择一项：1.弃置一张牌；2.你摸一张牌。",

  ["#luanfeng_double_swords-invoke"] = "鸾凤和鸣剑：你需弃置一张牌，否则 %src 摸一张牌",
  ["#luanfeng_double_swords_skill"] = "鸾凤和鸣剑",
}

local colorful_deer = fk.CreateCard{
  name = "&colorful_deer",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  equip_skill = "#colorful_deer_skill",
}
extension:addCardSpec("colorful_deer", Card.Heart, 13)
Fk:loadTranslationTable{
  ["colorful_deer"] = "七彩神鹿",
  [":colorful_deer"] = "装备牌·坐骑<br/><b>坐骑技能</b>：锁定技，你与其他角色的距离-1；当你造成属性伤害时，此伤害+1。",

  ["#colorful_deer_skill"] = "七彩神鹿",
}

local xingtian_axe = fk.CreateCard{
  name = "&xingtian_axe",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#xingtian_axe_skill",
}
extension:addCardSpec("xingtian_axe", Card.Diamond, 5)
Fk:loadTranslationTable{
  ["xingtian_axe"] = "刑天破军斧",
  [":xingtian_axe"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/>"..
  "<b>武器技能</b>：当你于出牌阶段内使用牌指定唯一目标后，你可以弃置两张牌，令其本回合不能使用或打出手牌且防具无效。",
}

local crow_bow = fk.CreateCard{
  name = "&crow_bow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#crow_bow_skill",
}
extension:addCardSpec("crow_bow", Card.Heart, 5)
Fk:loadTranslationTable{
  ["crow_bow"] = "金乌落日弓",
  [":crow_bow"] = "装备牌·武器<br/><b>攻击范围</b>：9<br/>"..
  "<b>武器技能</b>：当你于出牌阶段内一次失去至少两张手牌后，你可以弃置一名其他角色等量的牌。",

  ["#crow_bow_skill"] = "金乌落日弓",
  ["#crow_bow-choose"] = "金乌落日弓：你可以弃置一名其他角色%arg张牌",
}

local sanshou = fk.CreateCard{
  name = "&eq_sanshou",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#eq_sanshou_skill",
}
extension:addCardSpec("eq_sanshou", Card.Diamond, 12)
Fk:loadTranslationTable{
  ["eq_sanshou"] = "三首",
  [":eq_sanshou"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：当你受到伤害时，你可以亮出牌堆顶的三张牌，若其中有本回合未使用过的牌的类型，防止此伤害。",

  ["#eq_sanshou_skill"] = "三首",
}

local matchless_halberd = fk.CreateCard{
  name = "&matchless_halberd",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#matchless_halberd_skill",
}
extension:addCardSpec("matchless_halberd", Card.Diamond, 12)
Fk:loadTranslationTable{
  ["matchless_halberd"] = "无双方天戟",
  [":matchless_halberd"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/>"..
  "<b>武器技能</b>：你使用【杀】对目标角色造成伤害后，你可以摸一张牌或弃置其一张牌。",
}

local iron_double_halberd = fk.CreateCard{
  name = "&iron_double_halberd",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#iron_double_halberd_skill",
}
extension:addCardSpec("iron_double_halberd", Card.Diamond, 13)
Fk:loadTranslationTable{
  ["iron_double_halberd"] = "镔铁双戟",
  [":iron_double_halberd"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：你使用的【杀】被抵消后，你可以失去1点体力，然后获得此【杀】，摸一张牌，本回合使用【杀】的次数+1。",
}

local baipi_blade = fk.CreateCard{
  name = "&baipi_blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#baipi_blade_skill",
}
extension:addCardSpec("baipi_blade", Card.Spade, 2)
Fk:loadTranslationTable{
  ["baipi_blade"] = "百辟刀",
  [":baipi_blade"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：当你使用【杀】对目标角色造成伤害后，你可以获得其一张手牌。",
}

local lion_belt = fk.CreateCard{
  name = "&lion_belt",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#lion_belt_skill",
}
extension:addCardSpec("lion_belt", Card.Spade, 2)
Fk:loadTranslationTable{
  ["lion_belt"] = "玲珑狮蛮带",
  [":lion_belt"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：当其他角色使用牌指定你为唯一目标后，你可以进行一次判定，若判定结果为<font color='red'>♥</font>，则此牌对你无效。",
}

local red_robe = fk.CreateCard{
  name = "&red_robe",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#red_robe_skill",
}
extension:addCardSpec("red_robe", Card.Club, 1)
Fk:loadTranslationTable{
  ["red_robe"] = "红棉百花袍",
  [":red_robe"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，防止你受到的属性伤害。",
}

local golden_coronet = fk.CreateCard{
  name = "&golden_coronet",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#golden_coronet_skill",
}
extension:addCardSpec("golden_coronet", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["golden_coronet"] = "束发紫金冠",
  [":golden_coronet"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：准备阶段，你可以对一名其他角色造成1点伤害。",
}

local three_strategies = fk.CreateCard{
  name = "&three_strategies",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#three_strategies_skill",
}
extension:addCardSpec("three_strategies", Card.Spade, 5)
Fk:loadTranslationTable{
  ["three_strategies"] = "三略",
  [":three_strategies"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，你的攻击范围+1；你的手牌上限+1；你出牌阶段使用【杀】的次数+1。",
}

local bone_mirror = fk.CreateCard{
  name = "&bone_mirror",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#bone_mirror_skill",
}
extension:addCardSpec("bone_mirror", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["bone_mirror"] = "照骨镜",
  [":bone_mirror"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：出牌阶段结束时，你可以展示一张基本牌或普通锦囊牌，视为使用之。",
}

--合纵抗秦
local shangyang_reform = fk.CreateCard{
  name = "&shangyang_reform",
  type = Card.TypeTrick,
  skill = "shangyang_reform_skill",
  is_damage_card = true,
  damage_type = fk.NormalDamage,
}
extension:addCardSpec("shangyang_reform", Card.Spade, 5)
extension:addCardSpec("shangyang_reform", Card.Spade, 7)
extension:addCardSpec("shangyang_reform", Card.Spade, 9)
Fk:loadTranslationTable{
  ["shangyang_reform"] = "商鞅变法",
  [":shangyang_reform"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：你对目标角色造成随机1~2点伤害，若其因此伤害进入濒死状态，你判定，若为黑色，除其以外的角色不能对其使用【桃】直到濒死结算结束。",
}

local qin_dragon_sword = fk.CreateCard{
  name = "&qin_dragon_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#qin_dragon_sword_skill",
}
extension:addCardSpec("qin_dragon_sword", Card.Heart, 2)
Fk:loadTranslationTable{
  ["qin_dragon_sword"] = "真龙长剑",
  [":qin_dragon_sword"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/>"..
  "<b>武器技能</b>：锁定技，你每回合使用的第一张普通锦囊牌不能被抵消。",
}

local qin_seal = fk.CreateCard{
  name = "&qin_seal",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#qin_seal_skill",
}
extension:addCardSpec("qin_seal", Card.Heart, 7)
Fk:loadTranslationTable{
  ["qin_seal"] = "传国玉玺",
  [":qin_seal"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：出牌阶段开始时，你可以视为使用【南蛮入侵】、【万箭齐发】、【桃园结义】或【五谷丰登】。",
}

local qin_crossbow = fk.CreateCard{
  name = "&qin_crossbow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#qin_crossbow_skill",
}
extension:addCardSpec("qin_crossbow", Card.Club, 1)
Fk:loadTranslationTable{
  ["qin_crossbow"] = "秦弩",
  [":qin_crossbow"] = "装备牌·武器<br/><b>攻击范围</b>：9<br/>"..
  "<b>武器技能</b>：锁定技，出牌阶段，你使用【杀】的次数+1；当你使用【杀】指定一名目标后，你令其防具无效直到此【杀】结算完毕。",
}

--山河图
local lightning_cutter = fk.CreateCard{
  name = "&lightning_cutter",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#lightning_cutter_skill",
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)
    room:setPlayerMark(player, "lightning_cutter", 0)
  end,
}
extension:addCardSpec("lightning_cutter", Card.Club, 1)
Fk:loadTranslationTable{
  ["lightning_cutter"] = "雷切",
  [":lightning_cutter"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：锁定技，你每使用三张手牌后，使用的下一张【杀】伤害+1（不可叠加）。",

  ["#lightning_cutter_skill"] = "雷切",
  ["@@lightning_cutter"] = "雷切",
}

local douji_kiriyasu = fk.CreateCard{
  name = "&douji_kiriyasu",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#douji_kiriyasu_skill",
}
extension:addCardSpec("douji_kiriyasu", Card.Spade, 2)
Fk:loadTranslationTable{
  ["douji_kiriyasu"] = "童子切安纲",
  [":douji_kiriyasu"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：当你造成伤害时，若其已受伤，你可以防止此伤害，令其减1点体力上限。",

  ["#douji_kiriyasu-invoke"] = "童子切安纲：是否防止对 %dest 造成的伤害，改为令其减1点体力上限？",
  ["#douji_kiriyasu_skill"] = "童子切安纲",
}

local muramasa_blade = fk.CreateCard{
  name = "&muramasa_blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#muramasa_blade_skill",
}
extension:addCardSpec("muramasa_blade", Card.Spade, 6)
Fk:loadTranslationTable{
  ["muramasa_blade"] = "妖刀村正",
  [":muramasa_blade"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：锁定技，你使用的黑色【杀】伤害+1，当你使用【杀】指定目标后判定，若结果为黑色，则转移给随机合法目标。",

  ["#muramasa_blade_skill"] = "妖刀村正",
}

local shuriken = fk.CreateCard{
  name = "&shuriken",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 5,
  equip_skill = "#shuriken_skill",
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)
    room:setPlayerMark(player, "shuriken-turn", 0)
  end,
}
extension:addCardSpec("shuriken", Card.Heart, 5)
Fk:loadTranslationTable{
  ["shuriken"] = "手里剑",
  [":shuriken"] = "装备牌·武器<br/><b>攻击范围</b>：5<br/>"..
  "<b>武器技能</b>：锁定技，每名其他角色每回合限一次，当你对其他角色造成伤害时，其随机一个技能失效，直到其回合结束。",

  ["#shuriken_skill"] = "手里剑",
  ["@shuriken"] = "失效",
}

local hook_loop = fk.CreateCard{
  name = "&hook_loop",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#hook_loop_skill",
}
extension:addCardSpec("hook_loop", Card.Spade, 2)
Fk:loadTranslationTable{
  ["hook_loop"] = "钩镶",
  [":hook_loop"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，当你使用同花色或同点数【闪】响应【杀】后，你随机获得此【杀】使用者一张手牌。",

  ["#hook_loop_skill"] = "钩镶",
}

local mukashi_gusoku = fk.CreateCard{
  name = "&mukashi_gusoku",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#mukashi_gusoku_skill",
}
extension:addCardSpec("mukashi_gusoku", Card.Club, 2)
Fk:loadTranslationTable{
  ["mukashi_gusoku"] = "昔具足",
  [":mukashi_gusoku"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：当你受到大于1点的伤害或致命伤害时，你可以将装备区里的【昔具足】置入弃牌堆，本回合防止你受到的伤害。",

  ["#mukashi_gusoku_skill"] = "昔具足",
  ["@@mukashi_gusoku-turn"] = "昔具足",
}

local hasshaku_keikogyoku = fk.CreateCard{
  name = "&hasshaku_keikogyoku",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#hasshaku_keikogyoku_skill",
}
extension:addCardSpec("hasshaku_keikogyoku", Card.Heart, 5)
Fk:loadTranslationTable{
  ["hasshaku_keikogyoku"] = "八尺琼勾玉",
  [":hasshaku_keikogyoku"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，出牌阶段结束时，你回复1点体力；摸牌阶段，若你未受伤，你额外摸两张牌。",

  ["#hasshaku_keikogyoku_skill"] = "八尺琼勾玉",
}

local omamori = fk.CreateCard{
  name = "&omamori",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#omamori_skill",
}
extension:addCardSpec("omamori", Card.Diamond, 13)
Fk:loadTranslationTable{
  ["omamori"] = "平安御守",
  [":omamori"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，摸牌阶段开始时，你摸X张牌（X为你本局游戏杀死的角色数）。",

  ["#omamori_skill"] = "平安御守",
}

local golden_ring_armor = fk.CreateCard{
  name = "&golden_ring_armor",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#golden_ring_armor_skill",
  on_uninstall = function(self, room, player)
    Armor.onUninstall(self, room, player)
    player:setSkillUseHistory("#golden_ring_armor_skill", 0, Player.HistoryTurn)
  end,
}
extension:addCardSpec("golden_ring_armor", Card.Spade, 2)
Fk:loadTranslationTable{
  ["golden_ring_armor"] = "金环衔鳞甲",
  [":golden_ring_armor"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，每回合限一次，当你成为其他角色使用牌的目标时，若此牌与其他角色对你使用的上一张牌的点数差大于等于3，则此牌无效。<br>"..
  "<font color=><small>桃园“三千7Kw9N”共创设计</small></font>",

  ["#golden_ring_armor_skill"] = "金环衔鳞甲",
}

local yitian_slayer = fk.CreateCard{
  name = "&yitian_slayer",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#yitian_slayer_skill",
}
extension:addCardSpec("yitian_slayer", Card.Spade, 6)
Fk:loadTranslationTable{
  ["yitian_slayer"] = "倚天弒逆",
  [":yitian_slayer"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/>"..
  "<b>武器技能</b>：锁定技，你使用【杀】造成伤害时，若受到伤害的角色本阶段手牌数未发生过变化，此伤害+1。<br>"..
  "<font color=><small>桃园“二糊”共创设计</small></font>",

  ["#yitian_slayer_skill"] = "倚天弒逆",
}

--开黑季
local thunder_god_help = fk.CreateCard{
  name = "&thunder_god_help",
  type = Card.TypeTrick,
  skill = "thunder_god_help_skill",
  multiple_targets = true,
  damage_type = fk.ThunderDamage,
}
extension:addCardSpec("thunder_god_help", Card.Spade, 8)
extension:addCardSpec("thunder_god_help", Card.Heart, 8)
extension:addCardSpec("thunder_god_help", Card.Club, 8)
extension:addCardSpec("thunder_god_help", Card.Diamond, 8)
Fk:loadTranslationTable{
  ["thunder_god_help"] = "雷公助我",
  [":thunder_god_help"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：所有角色<br/>"..
  "<b>效果</b>：目标角色依次进行一次【闪电】判定，然后每有目标角色因此受到伤害，你摸一张牌。",

  ["thunder_god_help_skill"] = "雷公助我",
  ["#thunder_god_help_skill"] = "所有角色进行【闪电】判定，你摸因此造成伤害次数的牌",
}

local sharing_risk = fk.CreateCard{
  name = "&sharing_risk",
  type = Card.TypeTrick,
  skill = "sharing_risk_skill",
  multiple_targets = true,
}
extension:addCardSpec("sharing_risk", Card.Spade, 6)
extension:addCardSpec("sharing_risk", Card.Heart, 6)
extension:addCardSpec("sharing_risk", Card.Club, 6)
extension:addCardSpec("sharing_risk", Card.Diamond, 6)
Fk:loadTranslationTable{
  ["sharing_risk"] = "有难同当",
  [":sharing_risk"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：所有角色<br/>"..
  "<b>效果</b>：目标角色横置武将牌。",

  ["sharing_risk_skill"] = "有难同当",
  ["#sharing_risk_skill"] = "所有角色横置武将牌",
}

--两肋插刀 ♣10 ♠10 ♦10 ♥10
--劝酒 ♥Q ♣Q ♠Q
--落井下石 ♥7
--兄弟齐心 ♠J ♦J
--生死与共 ♦4 ♠4
--红运当头 ♣5 ♦5 ♠5
--无天无界 ♥K

local amazing_mushroom = fk.CreateCard{
  name = "&amazing_mushroom",
  type = Card.TypeTrick,
  skill = "amazing_mushroom_skill",
  multiple_targets = true,
}
extension:addCardSpec("amazing_mushroom", Card.NoSuit, 0)
Fk:loadTranslationTable{
  ["amazing_mushroom"] = "五菇丰登",
  [":amazing_mushroom"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：所有角色<br/>"..
  "<b>效果</b>：随机亮出五只菌子，目标角色依次选择其中一个，未因此选择的角色失去1点体力。",

  ["amazing_mushroom_skill"] = "五菇丰登",
  ["#amazing_mushroom_skill"] = "亮出五只菌子，可能是美味或拉完！",
  ["@!!amazing_mushroom"] = "五菇丰登",
  [":@!!amazing_mushroom"] = "未知效果",
  ["@!!good_mushroom-turn"] = "美味！",
  [":@!!good_mushroom-turn"] = "本回合使用牌有概率随机执行一个好效果：<br>"..
  "摸两张牌；回复1点体力，额外结算一次，分配2点伤害，本回合获得一个有用的技能",
  ["#amazing_mushroom-damage"] = "五菇丰登：选择一名角色对其造成2点伤害，或选择两名角色对其各造成1点伤害",
  ["@!!bad_mushroom-turn"] = "拉完！",
  [":@!!bad_mushroom-turn"] = "本回合使用牌有概率随机执行一个坏效果：<br>"..
  "随机弃置两张手牌；失去1点体力，随机指定目标，随机重铸一张手牌，本回合获得一个没用的技能",
}

local luoyang_shovel = fk.CreateCard{
  name = "&luoyang_shovel",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "luoyang_shovel_skill&",
}
extension:addCardSpec("luoyang_shovel", Card.Spade, 13)
Fk:loadTranslationTable{
  ["luoyang_shovel"] = "洛阳铲",
  [":luoyang_shovel"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：出牌阶段限一次，你可以弃置一张黑色牌，将所有手牌置入弃牌堆，摸等量的牌。",

  ["luoyang_shovel_skill&"] = "洛阳铲",
}

extension:loadCardSkels {
  grain_cart,
  caltrop_cart,
  wheel_cart,

  jade_comb,
  rhino_comb,
  golden_comb,

  sizhao_sword,
  armillary_sphere,
  catapult,
  blood_blade,
  colorful_lotus,

  ghost_dragon_blade,
  sage_cloak,
  fire_string,
  mystical_diagram,
  juechenjinge,
  asura_halberd,
  blood_sword,
  illusory_coronet,
  luanfeng_double_swords,
  colorful_deer,
  xingtian_axe,
  crow_bow,
  --abdication_edict,
  --snake_coiffure,
  sanshou,

  matchless_halberd,
  iron_double_halberd,
  baipi_blade,
  lion_belt,
  red_robe,
  golden_coronet,
  three_strategies,
  bone_mirror,

  shangyang_reform,
  qin_dragon_sword,
  qin_seal,
  qin_crossbow,

  lightning_cutter,
  douji_kiriyasu,
  muramasa_blade,
  shuriken,
  hook_loop,
  mukashi_gusoku,
  hasshaku_keikogyoku,
  omamori,
  golden_ring_armor,
  yitian_slayer,

  thunder_god_help,
  sharing_risk,

  amazing_mushroom,

  luoyang_shovel,
}

return extension
