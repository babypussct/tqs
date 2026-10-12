# CP19 skill inventory and upstream mapping

This report is generated from the pinned Lua runtime and audits `General.other_skills` directly. It is intentionally not based on `General:getSkillNameList()`, which drops unresolved strings.

- Baseline: 353 identities / 339 visible / 595 unique direct IDs / 203 missing IDs (205 occurrences).
- Dependency-complete scoped runtime: 8870 registered skills; 0 unresolved direct IDs across the original 353 generals.
- Visible invariant: PASS; unresolved visible IDs: none.
- Translation re-audit: 562 visible direct IDs; CJK heuristic remains 0 names and 0 descriptions.

## Pinned upstream versions

| Runtime package | Commit | Role |
| --- | --- | --- |
| `freekill-core` | `ade837d74c616dbd2d169934b0bec4a5a5dc0a85` | core |
| `utility` | `f86d3d05b5a6835584323e56ab85db1fd87ddacf` | extension |
| `hegemony` | `d616978ad2a53055f5815f3ae19f2d2b239862e0` | extension |
| `standard_ex` | `b041d9d4151d436bb6c357f7b772fa2f1a040df0` | skill-dependency |
| `shzl` | `a6743be11ac36db4efb57c5c2546102e2be805a0` | skill-dependency |
| `yj` | `10edd0f42f492eaeece5de14a6ef19aa14560cd0` | skill-dependency |
| `mobile` | `dcd523cc887e5bd010b26b7450486ab26f54d5ac` | skill-dependency |
| `sp` | `ab42a3fbba1e15e424b942e29ac8e0157c7086fc` | skill-dependency |
| `tenyear` | `91a769c87f48006cce3e1ded90e4a1beb028f7ad` | skill-dependency |
| `overseas` | `6780626a34f9fdafa25e15772b9f0609c62c7999` | skill-dependency |
| `ol` | `ceee01b97dfc0b01eae27e6d5f2fabf6ead46413` | skill-dependency |

## 203-ID mapping

The declaration column is the internal package that exposed the missing string. The implementation column records the first exact pinned source location (and all exact owners when more than one exists). A `declaration-repaired` row is an evidence-backed rename to an exact owner; no variant rules are copied or aliased.

Classification counts: `resolved-by-dependency`=202, `declaration-repaired`=1.

| ID | Declaration package @ upstream | Occurrences | Classification | Exact implementation / repair evidence |
| --- | --- | ---: | --- | --- |
| `aocai` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/aocai.lua:2` |
| `bazhen` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/fire/skills/bazhen.lua:2` |
| `beige` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/mountain/skills/beige.lua:2` |
| `beizhu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/beizhu.lua:2` |
| `benyu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/benyu.lua:2` |
| `bingqing` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/bingqing.lua:2` |
| `bingzheng` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/bingzheng.lua:2` |
| `bushi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/bushi.lua:2` |
| `buyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2011/skills/buyi.lua:2` |
| `caiyuan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/caiyuan.lua:2` |
| `choufa` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/choufa.lua:2` |
| `choutao` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/choutao.lua:2` |
| `ciwei` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/ciwei.lua:2` |
| `congjian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/thunder/skills/congjian.lua:2` |
| `dangxian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2012/skills/dangxian.lua:2` |
| `danlao` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/danlao.lua:2` |
| `dengli` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_shiji/skills/dengli.lua:2` |
| `difei` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_shiji/skills/difei.lua:2` |
| `dimeng` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/forest/skills/dimeng.lua:2` |
| `duanfa` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_xinghuo/skills/duanfa.lua:2` |
| `dujin` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_rare/skills/dujin.lua:2` |
| `duwu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/duwu.lua:2` |
| `ex__fanjian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `standard_ex@b041d9d4151d pkg/general/skills/fanjian.lua:14` |
| `ex__guicai` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `standard_ex@b041d9d4151d pkg/general/skills/guicai.lua:3` |
| `ex__rende` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `standard_ex@b041d9d4151d pkg/general/skills/rende.lua:2` |
| `ex__tuxi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `standard_ex@b041d9d4151d pkg/general/skills/tuxi.lua:12` |
| `ex__yingzi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `standard_ex@b041d9d4151d pkg/general/skills/yingzi.lua:3` |
| `fangquan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/mountain/skills/fangquan.lua:2` |
| `fengpo` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/fengpo.lua:2` |
| `fengzi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/fengzi.lua:2` |
| `fenli` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2014/skills/fenli.lua:2` |
| `fenwei` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `standard_ex@b041d9d4151d pkg/general/skills/fenwei.lua:12` |
| `fenyin` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_rare/skills/fenyin.lua:2` |
| `fuji` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/fuji.lua:2` |
| `fusong` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/fusong.lua:2` |
| `fuyin` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/thunder/skills/fuyin.lua:2` |
| `ganlu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2011/skills/ganlu.lua:3` |
| `gongqing` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_xinghuo/skills/gongqing.lua:2` |
| `guanchao` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_xinghuo/skills/guanchao.lua:2` |
| `guidao` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/wind/skills/guidao.lua:2` |
| `guzheng` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/mountain/skills/guzheng.lua:2` |
| `hanzhan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/ol_ex/skills/hanzhan.lua:2` |
| `haoshi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/forest/skills/haoshi.lua:2` |
| `hongyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/hongyi.lua:2` |
| `hongyuan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/hongyuan.lua:2` |
| `huanshi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/huanshi.lua:2` |
| `huituo` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2015/skills/huituo.lua:2` |
| `huoji` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/fire/skills/huoji.lua:2` |
| `huomo` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2015/skills/huomo.lua:2` |
| `huoshou` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/forest/skills/huoshou.lua:2` |
| `jiang` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/mountain/skills/jiang.lua:2` |
| `jianzhengq` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2017/skills/jianzheng.lua:2` |
| `jiaojin` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2014/skills/jiaojin.lua:2` |
| `jiaozi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/jiaozi.lua:2` |
| `jilei` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/jilei.lua:2` |
| `jishe` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2016/skills/jishe.lua:2` |
| `jizhan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/jizhan.lua:2` |
| `juedi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/juedi.lua:2` |
| `jueqing` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2011/skills/jueqing.lua:2` |
| `jueyong` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/jueyong.lua:2` |
| `jungong` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_shiji/skills/jungong.lua:2` |
| `juxiang` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/forest/skills/juxiang.lua:2` |
| `kanpo` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/fire/skills/kanpo.lua:2` |
| `kuangbi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2016/skills/kuangbi.lua:2` |
| `kuangli` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_lxxh/skills/kuangli.lua:2` |
| `langmie` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | declaration-repaired | `langmie` → `ty__langmie`; variant `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/langmie.lua:2` |
| `leiji` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/wind/skills/leiji.lua:2` |
| `lianhuan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/fire/skills/lianhuan.lua:2` |
| `lianhuo` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2016/skills/lianhuo.lua:3` |
| `lieren` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/forest/skills/lieren.lua:2` |
| `liyu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `standard_ex@b041d9d4151d pkg/general/skills/liyu.lua:14` |
| `longyin` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2013/skills/longyin.lua:2` |
| `longyuan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/longyuan.lua:2` |
| `luanwu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/forest/skills/luanwu.lua:2` |
| `lulue` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/lulue.lua:2` |
| `m_ex__anxu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/yj_ex/skills/anxu.lua:2` |
| `m_ex__danshou` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/yj_ex/skills/danshou.lua:2` |
| `m_ex__ganlu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/yj_ex/skills/ganlu.lua:2` |
| `m_ex__pingkou` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/yj_ex/skills/pingkou.lua:2` |
| `m_ex__yaoming` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/yj_ex/skills/yaoming.lua:2` |
| `midao` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/midao.lua:2` |
| `mingjian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2015/skills/mingjian.lua:2` |
| `mingzhe` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/mingzhe.lua:2` |
| `mizhao` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/mizhao.lua:2` |
| `mobile__jiaohua` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/jiaohua.lua:2` |
| `mobile__yanjiao` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_shiji/skills/yanjiao.lua:2` |
| `naxiang` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/naxiang.lua:2` |
| `niepan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/fire/skills/niepan.lua:2` |
| `nos__yaowu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/ol_other/skills/yaowu.lua:3` |
| `ol__huishi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/huishi.lua:2` |
| `ol__qiluan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/qiluan.lua:2` |
| `ol__shenxian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/shenxian.lua:3` |
| `ol__wanwei` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/wanwei.lua:2` |
| `ol__xuehen` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/xuehen.lua:2` |
| `ol__zhendu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/zhendu.lua:2` |
| `ol_ex__pojun` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/ol_exyj/skills/pojun.lua:2` |
| `os__baiyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_sp/skills/os_baiyi.lua:2` |
| `os__beini` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/beini.lua:2` |
| `os__chengxi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/chengxi.lua:2` |
| `os__chuhai` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/chuhai.lua:2` |
| `os__congji` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/congji.lua:2` |
| `os__dengjian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/dengjian.lua:2` |
| `os__dingfa` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/dingfa.lua:2` |
| `os__fenghan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/fenghan.lua:2` |
| `os__fengpo` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_sp/skills/os_fengpo.lua:2` |
| `os__guoyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/guoyi.lua:2` |
| `os__hongju` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_sp/skills/os_hongju.lua:2` |
| `os__huiyuan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_huiyuan.lua:2` |
| `os__jiange` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/jiange.lua:2` |
| `os__jianming` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/jianming.lua:2` |
| `os__jiaohua` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_jiaohua.lua:2` |
| `os__jieyu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/jieyu.lua:2` |
| `os__jiezhan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_if/skills/jiezhan.lua:2` |
| `os__jinglue` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_sp/skills/os_jinglue.lua:2`<br>`overseas@6780626a34f9 pkg/overseas_sp/skills/os_jinglue.lua:19` |
| `os__jintao` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_jintao.lua:2` |
| `os__kuanji` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/kuanji.lua:2` |
| `os__liechi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_sp/skills/os_liechi.lua:2` |
| `os__longjin` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_if/skills/longjin.lua:2` |
| `os__mibei` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/mibei.lua:2` |
| `os__moukui` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_sp/skills/os_moukui.lua:2` |
| `os__qingkou` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_qingkou.lua:2` |
| `os__shengxi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/shengxi.lua:2` |
| `os__shenyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/os_shenyi.lua:2` |
| `os__shigong` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_shigong.lua:2` |
| `os__shoushou` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_shoushou.lua:2` |
| `os__sidai` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/sidai.lua:2` |
| `os__tanfeng` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_tanfeng.lua:2` |
| `os__tujue` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/tujue.lua:2` |
| `os__xiawang` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/xiawang.lua:2` |
| `os__xinghan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/os_xinghan.lua:2` |
| `os__xingqi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/xingqi.lua:2` |
| `os__xinshou` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/os_xinshou.lua:2` |
| `os__xuewei` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_sp/skills/os_xuewei.lua:2` |
| `os__yangshi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_yangshi.lua:2` |
| `os__yulong` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_wuxia/skills/yulong.lua:2` |
| `os__zaoli` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_strategizing/skills/zaoli.lua:2` |
| `os__zhengrong` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_sp/skills/os_zhengrong.lua:2` |
| `os__zhenxi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/os_zhenxi.lua:2` |
| `os__zhuidu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_yizhu/skills/zhuidu.lua:2` |
| `os_ex__bingyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_ex/skills/os_ex_bingyi.lua:2` |
| `os_ex__jingce` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_ex/skills/os_ex_jingce.lua:2` |
| `os_ex__shenxing` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_ex/skills/os_ex_shenxing.lua:2` |
| `os_ex__yuzhang` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `overseas@6780626a34f9 pkg/overseas_ex/skills/os_ex_yuzhang.lua:2` |
| `poxiang` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/poxiang.lua:2` |
| `qiangwu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/qiangwu.lua:3` |
| `qiangzhi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2014/skills/qiangzhi.lua:3` |
| `qiaobian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/mountain/skills/qiaobian.lua:2` |
| `qingleng` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/qingleng.lua:2` |
| `qinguo` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_xinghuo/skills/qinguo.lua:2` |
| `qingzhong` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/qingzhong.lua:2` |
| `quanbian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/quanbian.lua:2` |
| `quanfeng` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/quanfeng.lua:2` |
| `quanjian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/quanjian.lua:2` |
| `quhu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/fire/skills/quhu.lua:2` |
| `re__qianxi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp_re/skills/qianxi.lua:2` |
| `shangshi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2011/skills/shangshi.lua:3` |
| `shefu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/shefu.lua:2` |
| `shenxian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/shenxian.lua:3` |
| `sheyan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/sheyan.lua:2` |
| `sheyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_shiji/skills/sheyi.lua:2` |
| `shidu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/shidu.lua:2` |
| `shishoul` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_lxxh/skills/shishou.lua:2` |
| `sp__youdi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_xinghuo/skills/youdi.lua:2` |
| `tairan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/tairan.lua:2` |
| `tianbian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2017/skills/tianbian.lua:2` |
| `tianming` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/tianming.lua:2` |
| `tianyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 2 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/fire/skills/tianyi.lua:2` |
| `tianyin` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_shiji/skills/tianyin.lua:2` |
| `tiaoxin` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 2 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/mountain/skills/tiaoxin.lua:2` |
| `ty__duanxie` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/duanxie.lua:2` |
| `ty__fenming` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/fenming.lua:2` |
| `ty__shengxi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/shengxi.lua:2` |
| `wangliec` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/thunder/skills/wanglie.lua:2` |
| `wansha` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/forest/skills/wansha.lua:2` |
| `weijing` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/weijing.lua:2` |
| `weiming` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/weiming.lua:2` |
| `wenji` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/wenji.lua:2` |
| `xiangle` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/mountain/skills/xiangle.lua:2` |
| `xiangshu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/xiangshu.lua:2` |
| `xiantu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2014/skills/xiantu.lua:2` |
| `xingshang` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/forest/skills/xingshang.lua:2` |
| `xiongluan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/thunder/skills/xiongluan.lua:2` |
| `xiongsi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_lxxh/skills/xiongsi.lua:2` |
| `xiongzhi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/xiongzhi.lua:2` |
| `xuetu` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/xuetu.lua:2` |
| `xunxian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_xinghuo/skills/xunxian.lua:2` |
| `yanxi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/yanxi.lua:2` |
| `yimie` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/yimie.lua:2` |
| `yinbing` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `sp@ab42a3fbba1e pkg/sp/skills/yinbing.lua:2` |
| `yingshis` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/yingshi.lua:2`<br>`ol@ceee01b97dfc pkg/wende/skills/yingshi.lua:20` |
| `yishe` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/xinghe/skills/yishe.lua:2` |
| `yishi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/yishi.lua:2` |
| `yizan` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/yizan.lua:2` |
| `zenhui` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2014/skills/zenhui.lua:2` |
| `zhaoran` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `ol@ceee01b97dfc pkg/wende/skills/zhaoran.lua:2` |
| `zhijian` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/mountain/skills/zhijian.lua:2` |
| `zhiyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_sp/skills/zhiyi.lua:2` |
| `zhuandui` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2017/skills/zhuandui.lua:2` |
| `zhuixi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `tenyear@91a769c87f48 pkg/tenyear_huicui/skills/zhuixi.lua:2` |
| `zhuiyi` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2012/skills/zhuiyi.lua:2` |
| `zuilun` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `shzl@a6743be11ac3 pkg/thunder/skills/zuilun.lua:2` |
| `zuoding` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `yj@10edd0f42f49 pkg/yj2015/skills/zuoding.lua:2` |
| `zuoyou` | `hegemony@d616978ad2a53055f5815f3ae19f2d2b239862e0` | 1 | resolved-by-dependency | `mobile@dcd523cc887e pkg/mobile_lxxh/skills/zuoyou.lua:2` |

## Gate

The release build invokes `npm run audit:skills` before TypeScript/Vite compilation. It exits non-zero whenever a baseline visible general has a direct skill string absent from `Fk.skills`; the audit cannot report PASS for an unresolved visible skill.
