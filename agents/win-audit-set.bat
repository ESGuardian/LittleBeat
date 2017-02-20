@echo off
rem audit set
rem ** Система **
rem  Расширение системы безопасности
auditpol /set /subcategory:"{0CCE9211-69AE-11D9-BED3-505054503030}" /success:disable /failure:disable
rem  Изменение состояния безопасности 
auditpol /set /subcategory:"{0CCE9210-69AE-11D9-BED3-505054503030}" /success:disable /failure:disable
rem  Целостность системы
auditpol /set /subcategory:"{0CCE9212-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Другие системные события 
auditpol /set /subcategory:"{0CCE9214-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable

rem ** Вход/выход  **
rem  Вход в систему 
auditpol /set /subcategory:"{0CCE9215-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Выход из системы 
auditpol /set /subcategory:"{0CCE9216-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Блокировка учетной записи
auditpol /set /subcategory:"{0CCE9217-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Специальный вход 
auditpol /set /subcategory:"{0CCE921B-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Другие события входа и выхода
auditpol /set /subcategory:"{0CCE921C-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Сервер сетевых политик
auditpol /set /subcategory:"{0CCE9243-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable

rem ** Доступ к объектам **
rem  Файловая система
auditpol /set /subcategory:"{0CCE921D-69AE-11D9-BED3-505054503030}" /success:disable /failure:disable
rem  Реестр
auditpol /set /subcategory:"{0CCE921E-69AE-11D9-BED3-505054503030}" /success:disable /failure:disable
rem  Объект-задание
auditpol /set /subcategory:"{0CCE921F-69AE-11D9-BED3-505054503030}" /success:disable /failure:disable
rem  Службы сертификации
auditpol /set /subcategory:"{0CCE9221-69AE-11D9-BED3-505054503030}" /success:disable /failure:disable
rem  Создано приложением
auditpol /set /subcategory:"{0CCE9222-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Общий файловый ресурс
auditpol /set /subcategory:"{0CCE9224-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Съемные носители
auditpol /set /subcategory:"{0CCE9245-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable


rem ** Подробное отслеживание **
rem  Создание процесса 
auditpol /set /subcategory:"{0CCE922B-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Завершение процесса
auditpol /set /subcategory:"{0CCE922C-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Активность DPAPI
auditpol /set /subcategory:"{0CCE922D-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable

rem ** Изменение политики **
rem  Аудит изменения политики
auditpol /set /subcategory:"{0CCE922F-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Изменение политики проверки подлинности
auditpol /set /subcategory:"{0CCE9230-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Изменение политики авторизации
auditpol /set /subcategory:"{0CCE9231-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable

rem ** Учетные записи **
rem  Управление учетными записями
auditpol /set /subcategory:"{0CCE9235-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Управление учетной записью компьютера
auditpol /set /subcategory:"{0CCE9236-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Управление группой безопасности 
auditpol /set /subcategory:"{0CCE9237-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Управление группой распространения
auditpol /set /subcategory:"{0CCE9238-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Управление группой приложений
auditpol /set /subcategory:"{0CCE9239-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Другие события управления учетной записью
auditpol /set /subcategory:"{0CCE923A-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable

rem ** Вход учетной записи **
rem  Проверка учетных данных
auditpol /set /subcategory:"{0CCE923F-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Операции с билетами службы Kerberos
auditpol /set /subcategory:"{0CCE9240-69AE-11D9-BED3-505054503030}" /success:disable /failure:enable
rem  Другие события входа учетных записей
auditpol /set /subcategory:"{0CCE9241-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
rem  Служба проверки подлинности Kerberos
auditpol /set /subcategory:"{0CCE9242-69AE-11D9-BED3-505054503030}" /success:disable /failure:enable