# monsol
Инструмент мотниторинга ноды Solana

### Использование
bash <(wget -qO- https://raw.githubusercontent.com/SimyriK/monsol/main/monsol.sh)

Фунционал:
- Проверяет, чтобы запущена была установленная версия. (Иногда бывает, что после обновления запущена старая версия).
- Проверяет вывод catchup.
- Проверяет, что нода набирает кредиты.
- Проверяет баланс и предлагает его пополнить его с vote аккаунта в случае когда баланс менее 50 SOL.
- Проверяет скипрейт.
