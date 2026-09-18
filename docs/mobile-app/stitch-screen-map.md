# Stitch Screen Map

This document bridges the NEW Stitch visual design to the Flutter implementation.

| Stitch Screen / Component | Screen ID | Flutter Route / Page | Feature | Required State / Overlay |
|---|---|---|---|---|
| Splash / Loading | - | / | pp | Auth initialization |
| Phone Login | - | /login | uth | Form validation, OTP modal |
| OTP Verification | - | /verify | uth | Timer, resend cooldown |
| Business Setup | - | /setup | usiness_setup | Business name/type form |
| Home Dashboard | - | /home | home | Summary stats, recent tx |
| Receipt Camera | - | /capture | eceipt_capture | Camera overlay, quality warning |
| Review / Edit | - | /review | i_extraction | Editable form, confidence flags |
| Transaction List | - | /transactions | 	ransactions | List, filters |
| Transaction Detail| - | /transaction/:id | 	ransactions | Read-only details, image view |
| Category Management| - | /categories | categories | List, Add custom category |
| Reports | - | /reports | eports | Date range selector, charts |
| Settings | - | /settings | settings | Profile, logout |

> Note: Where specific Stitch IDs become available, update this map.
