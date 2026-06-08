# ART-LAVKA Copy Library (RU / UZ / EN)

Single source for user-facing strings (SPEC §11). Each row maps a stable key
(used by `FailureCode` / l10n) to the three languages. EN is the reference.

When wiring l10n in the apps, generate ARB files from this table. Keys stay
identical across apps so copy is written once.

## Error messages

| Key | EN | RU | UZ |
|---|---|---|---|
| `network` | No connection. Check your internet and try again. | Нет соединения. Проверьте интернет и попробуйте снова. | Aloqa yo'q. Internetni tekshirib, qayta urinib ko'ring. |
| `server` | Something went wrong. Please try again. | Что-то пошло не так. Попробуйте ещё раз. | Nimadir xato ketdi. Iltimos, qayta urinib ko'ring. |
| `otp_wrong` | That code isn't right. Check it and try again. | Неверный код. Проверьте и попробуйте снова. | Kod noto'g'ri. Tekshirib, qayta urinib ko'ring. |
| `otp_expired` | This code has expired. Request a new one. | Срок действия кода истёк. Запросите новый. | Kod muddati tugadi. Yangisini so'rang. |
| `otp_throttled` | Too many attempts. Please wait a moment before trying again. | Слишком много попыток. Подождите немного и попробуйте снова. | Urinishlar juda ko'p. Biroz kutib, qayta urinib ko'ring. |
| `invalid_phone` | Enter a valid phone number. | Введите корректный номер телефона. | To'g'ri telefon raqamini kiriting. |
| `validation` | This field is required. | Это поле обязательно. | Bu maydon to'ldirilishi shart. |
| `payment_failed` | Payment didn't go through. No money was taken — please try again. | Платёж не прошёл. Деньги не списаны — попробуйте снова. | To'lov amalga oshmadi. Pul yechilmadi — qayta urinib ko'ring. |
| `royalty_out_of_bounds` | Royalty must be between {min} and {max} UZS. | Роялти должно быть от {min} до {max} сум. | Royalti {min} dan {max} so'mgacha bo'lishi kerak. |
| `upload_too_small` | This image is too small to print well. Use at least {w}×{h}px. | Изображение слишком маленькое для печати. Минимум {w}×{h}px. | Rasm chop etish uchun juda kichik. Kamida {w}×{h}px bo'lsin. |
| `upload_wrong_format` | Use a PNG or JPG file. | Используйте файл PNG или JPG. | PNG yoki JPG faylidan foydalaning. |
| `upload_rejected` | This design wasn't approved. Reason: {reason}. | Дизайн не одобрен. Причина: {reason}. | Dizayn tasdiqlanmadi. Sabab: {reason}. |
| `below_payout_threshold` | You can withdraw once your balance reaches {min} UZS. | Вывод доступен, когда баланс достигнет {min} сум. | Balans {min} so'mga yetganda yechib olishingiz mumkin. |
| `cart_item_unavailable` | This item is no longer available and was removed from your cart. | Этот товар больше недоступен и удалён из корзины. | Bu mahsulot endi mavjud emas va savatdan olib tashlandi. |
| `session_expired` | You've been signed out. Please log in again. | Вы вышли из аккаунта. Войдите снова. | Tizimdan chiqdingiz. Iltimos, qayta kiring. |
| `seller_not_verified` | Your seller account is still under review. | Ваш аккаунт продавца на проверке. | Sotuvchi hisobingiz hali ko'rib chiqilmoqda. |

## Success messages

| Key | EN | RU | UZ |
|---|---|---|---|
| `otp_sent` | Code sent. Check your messages. | Код отправлен. Проверьте сообщения. | Kod yuborildi. Xabarlaringizni tekshiring. |
| `logged_in` | Welcome back! | С возвращением! | Xush kelibsiz! |
| `registered` | Account created. | Аккаунт создан. | Hisob yaratildi. |
| `order_placed` | Order placed! We're getting it ready. | Заказ оформлен! Мы готовим его. | Buyurtma qabul qilindi! Tayyorlamoqdamiz. |
| `payment_confirmed` | Payment received. Thank you! | Оплата получена. Спасибо! | To'lov qabul qilindi. Rahmat! |
| `review_submitted` | Thanks for your review. | Спасибо за отзыв. | Sharhingiz uchun rahmat. |
| `design_uploaded` | Uploaded! It's now in review. | Загружено! Дизайн на проверке. | Yuklandi! Endi ko'rib chiqilmoqda. |
| `design_approved` | Your design is live. | Ваш дизайн опубликован. | Dizayningiz efirga uzatildi. |
| `withdrawal_requested` | Withdrawal requested. We'll process it on the next payout. | Запрос на вывод принят. Обработаем при следующей выплате. | Yechib olish so'raldi. Keyingi to'lovda amalga oshiramiz. |
| `profile_saved` | Saved. | Сохранено. | Saqlandi. |
| `address_added` | Address added. | Адрес добавлен. | Manzil qo'shildi. |

## Tooltips

| Key | EN | RU | UZ |
|---|---|---|---|
| `tip_royalty` | Your earnings per item. We add this on top of the base cost. | Ваш заработок с каждого товара. Добавляется к базовой стоимости. | Har bir mahsulotdan daromadingiz. Asosiy narx ustiga qo'shiladi. |
| `tip_base_cost` | Covers the blank product, printing, and packaging. | Покрывает сам товар, печать и упаковку. | Mahsulot, chop etish va qadoqlashni qoplaydi. |
| `tip_pending` | We review every design before it goes live — usually within a day. | Мы проверяем каждый дизайн перед публикацией — обычно за день. | Har bir dizaynni efirga chiqishdan oldin ko'rib chiqamiz — odatda bir kun ichida. |
| `tip_print_zone` | Keep important details inside the dashed area. | Держите важные детали внутри пунктирной области. | Muhim qismlarni punktir chiziq ichida saqlang. |
| `tip_rating` | Tap to rate from 1 to 5. | Нажмите, чтобы оценить от 1 до 5. | 1 dan 5 gacha baholash uchun bosing. |

## Empty states

| Key | EN | RU | UZ |
|---|---|---|---|
| `empty_cart` | Your cart is empty. Find something you love. | Корзина пуста. Найдите что-то по душе. | Savatingiz bo'sh. O'zingizga yoqqanini toping. |
| `no_orders` | No orders yet. Your future purchases show up here. | Заказов пока нет. Здесь появятся ваши покупки. | Hozircha buyurtmalar yo'q. Xaridlaringiz shu yerda paydo bo'ladi. |
| `no_designs` | No designs yet. Upload your first print to start earning. | Дизайнов пока нет. Загрузите первый принт, чтобы начать зарабатывать. | Hozircha dizaynlar yo'q. Daromad uchun birinchi printni yuklang. |
| `no_search_results` | Nothing matched that. Try another word. | Ничего не найдено. Попробуйте другое слово. | Hech narsa topilmadi. Boshqa so'z bilan urinib ko'ring. |
