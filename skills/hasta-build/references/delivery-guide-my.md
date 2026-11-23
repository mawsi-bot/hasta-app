# Hasta v1.0.0 — Perplexity AI Agent သို့ ပေးပို့နည်းလမ်း (Delivery Guide)

Package အစုံ: `Hasta_v1_Package.zip` (80KB) သို့မဟုတ် `Hasta_v1_BUNDLE_AllInOne.md` (154KB, ဖိုင်တစ်ခုတည်း) — နှစ်ခုလုံး 25MB အကုန်နည်သဖွင့် attachment limit ပြဿနာ မရှိပါ။

---

## Route A — အကောင်ဆုံး (တကယ့် code repo ရရန်): GitHub + Perplexity Computer

Perplexity Computer သည် file system၊ browser၊ command line ကို အသုံးခွင့်ပြီး GitHub connector ဖြင့် repo ကို ဖတ်၍ PR ဖွင့်/merge လုပ်နိုင်သည် (perplexity.ai/connectors/github)။ Max subscription ဖြင့် စတင်ပြီး Pro/Enterprise သို့ ဆင့်တင် ဖြန့်ချိထားပါတယ်ဟု ဆိုကြပါတယ် — subscription tier ကို နောက်ဆုံးအချိန် official page တွင် ပြန့်စစ်ပါ။

1. GitHub တွင် repo အသစ် `hasta-app` ဖွင့်ပါ (private ဖြင့် စတင်ပါ)။
2. `docs/` folder အောက်မှာ ဖိုင်များ တင်ပါ: `Hasta_v1_Master_PRD.md`, `Hasta_v1_API_Contract.md`, `Hasta_v1_Design_Tokens.json`, `Hasta_v1_Agent_Handoff_Prompt.md`, `Hasta_v1_Index.md`, `Hasta_v1_UI_Reference.html`။
3. Perplexity → **Computer** → Connectors → **GitHub** → authorize → repo `hasta-app` ကို ညွှန်ပါ။
4. ပထမ message အဖြစ် `Hasta_v1_Agent_Handoff_Prompt.md` ထဲက `=== PROMPT START === … === PROMPT END ===` block ကို **paste** ပါ (attach ထက် paste က ပိုတိတျတယ်)။ အဆုံးမှာ ထည့်ပါ:
   > `docs/` ရှိ SPEC 1.0.0 ကို read လုပ်ပါ။ Sprint 0 သာ အရင်လုပ်ပါ။ Code ကို `hasta-app` branch `feature/HAS-000-sprint0` တွင် PR ဖွင့်ပါ။
5. ထို့နောက် handoff prompt ၏ §3 က sprint prompt များကို **တစ်ခုတည်းချင့်** ပို့ပါ။ PR တိုင်းမှာ mapped test IDs (T1–T45) ပါမပါ စစ်ပါ။

**ဘဝတွင် ဒီ route ကို ရေးရင်း:** Flutter + NestJS monorepo၊ migrations၊ Terraform၊ CI gates စသည့် multi-file production engineering ကို file upload သာ ဖြင့်ရန် မလုံလောက် — agent သည့် repo file system ကို တိုက်ရိုက် ဝင်ထွက်နေရသဖွင့်။

---

## Route B — Perplexity Labs (prototype / UI demo အတွက်)

Labs သည် Pro subscription ဖြင့် ရနိုင်ပြီး report/dashboard/simple web app များ ထုတ်ပေးသည့် project workbench ဖြစ်ပါတယ် (Assets tab တွင် ဖိုင်များ download လို့ရ)။

- Attach: `Hasta_v1_UI_Reference.html` + `Hasta_v1_Design_Tokens.json` (သို့မဟုတ် bundle ဖိုင်)
- Prompt: "ဒီ design tokens နှင့် flow များအတိုင်း Hasta dating/chat screens 5 ခုကို interactive HTML prototype အဖြစ် ဆောက်ပေးပါ (mock data only)"
- **မစောင့်္စာရ:** Labs ရလဒ်ကို demo/mockup အဖြစ်သာ ယူပါ။ PRD၊ DDL၊ test matrix ကို Labs က production code အဖြစ် အပြည့်အဝ မဆောက်နိုင်ပါ။

---

## Route C — Space / thread (spec refinement အတွက်)

Perplexity **Space** တစ်ခု ဖွင့်ပြီး ဖိုင် ၄ ခု + UI ကို တင်ပါ။ Space သည် သီးသန့် docs set ပေါ်မူတည်၍ ဖြေသည့်အတွက် လမ်းညွှန်/ဗားရှင်းထိန်း အတွက် ကောင်းတယ်။
- အသုံးဝင်ပုံ: `[PROPOSAL]` tag များ (PRD §20) ကို legal sign-off အတွက် ပြန့်သုံးသုံးသပ်ရန်၊ edge case တွေ ထပ်ဖြည့်ရန်၊ test matrix ကို ပြန့်စစ်ရန်။
- Code ရေးရန်ဆိုလျှင့် Route A သို့ ပြောင်းပါ။

---

## Attachment များ ဘဝတွင် ပြောင်းလဲအခါ ဂရုပြုရန်

| ပြဿနာ | ဖြေရှင်း |
| --- | --- |
| Thread အဟောင်းတွင် file များ ပျောက်တယ်ဟု ဆိုကြပါတယ် | Sprint တိုင်းမှာ bundle ဖိုင်ကို ထပ် attach ပါ၊ သို့မဟုတ် Route A (GitHub) သုံးပါ |
| File limit (~25MB/file; free tier သည့် တစ်ရက် နည်းနည်းခုသာ upload ခွင့်ပေးသည် ဟု third-party sources တွင် ဆို) | ကျွန့်ုတို့ package သည့် 80–154KB သာ ဖြစ်သဖွင့် ပြဿနာ မရှိ။ သို့သော် အခွင့်အအား tier အလိုက် ကွာခွင့်နိုင်သဖွင့် account settings တွင် ပြန့်စစ်ပါ |
| Agent က sprint အားလုံးကို တပိုင်နက်တပိုင်နင်း ရေးမိမည် | "Sprint N သာ အကောင်အထည့်ဖော်ပါ၊ exit criteria မှာ mapped test IDs ပါစေ" ဟု ထပ်ထပ် ကန့်သတ်ပါ |
| Secrets လိုအပ်လာမည့် အချိန် | Google OAuth client ID/secret, FCM/APNs key, AWS credential တွင်ကို agent ထံ **ဘယ်တော့မှ မပို့ရ**။ `.env.example` တွင် placeholder အဖြစ်သာ ထားပါ၊ secrets ကို Secrets Manager တွင်သာ ထားပါ |
| Retention/limits ([PROPOSAL]) | legal review မလုပ်မီ hard-coded value အဖြစ် မထားရ — remote config default အဖြစ်သာ |

---

## ပေးပို့ပြီးပါက ပထမ 3 message အစဉ်

1. **Confirm prompt** (handoff block) → agent က stack + auth model ကို bullet အတိုင်း ပြန်ရေးရမည့်
2. **Sprint 0 request** → repo skeleton, CI static gates (T20/T36/T37/T45), Prisma identity schema, generated `tokens.dart`, i18n my/en
3. **Review request** → "repo tree + ဘယ် test matrix ID တွေ pass ဖြစ်ပြီလဲ ဇယားပြပါ၊ PRD နဲ့ မကိုက်ညီတာ ရှိရင် `[DEVIATION]` ဖြင့် စာရင်းပြပါ"

---

### Package ထဲမှာ ဘာပါလဲ

| File | အကြံပြု အသုံးပြုပုံ |
| --- | --- |
| `Hasta_v1_BUNDLE_AllInOne.md` | attachment များကို paste ပြောင်းရမည့်အခါ ဒီဖိုင်တစ်ခုတည်း သုံးပါ |
| `Hasta_v1_Package.zip` | GitHub commit / backup အတွက် |
| `Hasta_v1_Master_PRD.md` | single source of truth (spec) |
| `Hasta_v1_API_Contract.md` | endpoint + WS events |
| `Hasta_v1_Design_Tokens.json` | theme/token generation |
| `Hasta_v1_Agent_Handoff_Prompt.md` | paste-first prompt + sprint prompts |
| `Hasta_v1_UI_Reference.html` | visual reference (Route B) |
| `Hasta_v1_Index.md` | package map |

> Product note: Perplexity သည် research/orchestration agent ဖြစ်သဖြင့် code quality ကို CI (tests, lint, security scans) ဖြင့်သာ အဖြည့်ခွင့် တိုင်းတာပါ။ Agent ထုတ်ပေးသော code ကို human review မပါ ပရိုဒက်ရှန်တင်သည့်အရာ မဟုတ်ပါ။
